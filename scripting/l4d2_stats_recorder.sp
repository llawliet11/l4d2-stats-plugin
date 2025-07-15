#pragma semicolon 1
#pragma newdecls required

// #define DEBUG 1
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <geoip>
#include <sdkhooks>
#include <left4dhooks>
#include <jutils>
#include <l4d_info_editor>
#undef REQUIRE_PLUGIN
#include <l4d2_skill_detect>

// SETTINGS

// Each coordinate (x,y,z) is rounded to nearest multiple of this. 
#define HEATMAP_POINT_SIZE 10
#define MAX_HEATMAP_VISUALS 200
#define HEATMAP_PAGINATION_SIZE 500
#define DISTANCE_CALC_TIMER_INTERVAL 4.0

public Plugin myinfo = 
{
	name =  "L4D2 Stats Recorder", 
	author = "jackzmc", 
	description = "", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/Jackzmc/sourcemod-plugins"
};

enum queryType {
	QUERY_ANY,
	QUERY_HEATMAPS,
	QUERY_WEAPON_STATS,
	QUERY_UPDATE_STAT,
	QUERY_POINTS,
	QUERY_UPDATE_USER,
	QUERY_UPDATE_NAME_HISTORY,
	QUERY_MAP_INFO,
	QUERY_MAP_RATE,
	_QUERY_MAX
}
char QUERY_TYPE_ID[_QUERY_MAX][] = {
	"-any-",
	"HEATMAPS",
	"WEAPON_STATS",
	"UPDATE_STAT",
	"POINTS",
	"UPDATE_USER",
	"UPDATE_USER_NAME_HISTORY",
	"MAP_INFO",
	"MAP_RATE"
};

static ConVar hServerTags, hZDifficulty, hClownMode, hPopulationClowns, hMinShove, hMaxShove, hClownModeChangeChance;
ConVar hHeatmapInterval;
ConVar hHeatmapActive;
static Handle hHonkCounterTimer;
Database g_db;
static char gamemode[32], serverTags[255];
static bool lateLoaded; //Has finale started?

int g_iLastBoomUser;
float g_iLastBoomTime;
Menu g_rateMenu;

// Tank damage tracking for multiple tanks support
int g_iTankDamage[MAXPLAYERS + 1];     // Per-tank damage tracking
bool g_bTankInPlay = false;            // Is tank currently active
int g_iTankClient = 0;                 // Current tank client ID
int g_iTankHealth = 0;                 // Current tank health
#define ZOMBIECLASS_TANK 8             // Tank zombie class ID

// Anti-abuse: Time-based heal cooldown system
int g_iLastHealTime[MAXPLAYERS + 1][MAXPLAYERS + 1]; // [healer][target] - last heal time
#define HEAL_COOLDOWN_TIME 300         // 5 minutes in seconds
#define HEAL_HEALTH_THRESHOLD 60       // Only award points if target health <= 60%
#define HEAL_CRITICAL_THRESHOLD 30     // Bonus points if target health <= 30%

char OFFICIAL_MAP_NAMES[14][] = {
	"Dead Center",   // c1
	"Dark Carnival", // c2
	"Swamp Fever",   // c3
	"Hard Rain",     // c4
	"The Parish",    // c5
	"The Passing",   // c6
	"The Sacrifice", // c7
	"No Mercy",      // c8
	"Crash Course",  // c9
	"Death Toll",    // c10
	"Dead Air",      // c11
	"Blood Harvest", // c12
	"Cold Stream",   // c13
	"Last Stand",    // c14
};

enum struct Game {
	int difficulty;
	int startTime;
	int finaleStartTime;
	int clownHonks;
	bool isVersusSwitched;
	bool finished; // finale_vehicle_ready triggered
	bool submitted; // finale_win triggered
	char gamemode[32];
	char uuid[64];
	char mapId[64];
	char mapTitle[128];
	char missionId[64];
	bool isCustomMap;

	bool IsVersusMode() {
		return StrEqual(this.gamemode, "versus") || StrEqual(this.gamemode, "scavenge");
	}

	void GetMap() {
		GetCurrentMap(this.mapId, sizeof(this.mapId));
		this.isCustomMap = this.mapId[0] != 'c' || !IsCharNumeric(this.mapId[1]) || !(IsCharNumeric(this.mapId[2]) || this.mapId[2] == 'm');
		if(this.isCustomMap)
			InfoEditor_GetString(0, "DisplayTitle", this.mapTitle, sizeof(this.mapTitle));
		else {
			int mapIndex = StringToInt(this.mapId[1]) - 1;
			strcopy(this.mapTitle, sizeof(this.mapTitle), OFFICIAL_MAP_NAMES[mapIndex]);
		}
		InfoEditor_GetString(0, "Name", this.missionId, sizeof(this.missionId));
		PrintToServer("[Stats] %s \"%s\" %s (c=%b)", this.mapId, this.mapTitle, this.missionId, this.isCustomMap);
	}
}

enum PointRecordType {
	PType_Generic = 0,
	PType_FinishCampaign,
	PType_CommonKill,
	PType_SpecialKill,
	PType_TankKill,
	PType_WitchKill,
	PType_TankKill_Solo,
	PType_TankKill_Melee,
	PType_Headshot,
	PType_FriendlyFire,
	PType_HealOther,
	PType_ReviveOther,
	PType_ResurrectOther,
	PType_DeployAmmo
}

enum struct WeaponStatistics {
	float minutesUsed;
	int totalDamage;
	int headshots;
	int kills;
}

#define MAX_VALID_WEAPONS 19
char VALID_WEAPONS[MAX_VALID_WEAPONS][] = {
	"weapon_melee", "weapon_chainsaw", "weapon_rifle_sg552", "weapon_smg", "weapon_rifle_ak47", "weapon_rifle", "weapon_rifle_desert", "weapon_pistol", "weapon_pistol_magnum", "weapon_autoshotgun", "weapon_shotgun_chrome", "weapon_sniper_scout", "weapon_sniper_military", "weapon_sniper_awp", "weapon_smg_silenced", "weapon_smg_mp5", "weapon_shotgun_spas", "weapon_rifle_m60", "weapon_pumpshotgun"
};

enum struct ActiveWeaponData {
	StringMap pendingStats;
	char classname[32];
	int pickupTime;
	int damage;
	int kills;
	int headshots;

	void Init() {
		this.Reset();
		this.pendingStats = new StringMap();
	}

	void Reset(bool full = false) {
		this.classname[0] = '\0';
		this.damage = 0;
		this.kills = 0;
		this.headshots = 0;
		this.pickupTime = 0;
		if(full) {
			this.Flush();
		}
	}

	void Flush() {
		if(this.pendingStats != null) {
			this.pendingStats.Clear();
		}
	}

	void SetActiveWeapon(int weapon) {
		if(this.pendingStats == null || !IsValidEntity(weapon)) return;

		// If there was a previous active weapon, up its data before we reset
		if(this.classname[0] != '\0') {
			WeaponStatistics stats;
			this.pendingStats.GetArray(this.classname, stats, sizeof(stats));
			stats.totalDamage += this.damage;
			stats.kills += this.kills;
			stats.headshots += this.headshots;
			if(this.pickupTime != 0)
				stats.minutesUsed += (GetTime() - this.pickupTime);
			this.pendingStats.SetArray(this.classname, stats, sizeof(stats));
		}

		// Reset the data for the new cur weapon
		this.Reset();

		// Check if it's a valid weapon
		char classname[32];
		GetEntityClassname(weapon, classname, sizeof(classname));
		for(int i = 0; i < MAX_VALID_WEAPONS; i++) {
			if(StrEqual(VALID_WEAPONS[i], classname)) {
				this.pickupTime = GetTime();
				if(StrEqual(classname, "weapon_melee")) {
					GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", this.classname, sizeof(this.classname));
				} else {
					strcopy(this.classname, sizeof(this.classname), classname);
				}
				break;
			}
		}
	}
}

enum struct DistanceCalculator {
	float accumulation;
	int recordTime;
	float lastPos[3];

	// TODO: in future, avg speed?
}
enum struct TimeCalculator {
	float seconds;
	int lastTime;
	bool enabled;
	// Starts calculator and marks timestamp, if not already started
	void TryStart() {
		if(!this.enabled) {
			this.enabled = true;
			this.lastTime = GetTime();
		}
	}
	// Record number of seconds, if enabled
	bool TryEnd() {
		if(this.enabled) {
			this.seconds += (GetTime() - this.lastTime);
			this.enabled = false;
			return true;
		}
		return false;
	}
}

enum struct Player {
	char steamid[32];
	int damageSurvivorGiven;
	int damageInfectedRec;
	int damageInfectedGiven;
	int damageSurvivorFF;
	int damageSurvivorFFCount;
	int damageFFTaken;
	int damageFFTakenCount;
	int doorOpens;
	int witchKills;
	int startedPlaying;
	int points;
	int upgradePacksDeployed;
	int finaleTimeStart;
	int molotovDamage;
	int pipeKills;
	int molotovKills;
	int minigunKills;
	int clownsHonked;
	DistanceCalculator distance;
	TimeCalculator timeInFire;
	TimeCalculator timeInAcid;

	//Used for table: stats_games;
	int m_checkpointZombieKills;
	int m_checkpointSurvivorDamage;
	int m_checkpointMedkitsUsed;
	int m_checkpointPillsUsed;
	int m_checkpointMolotovsUsed;
	int m_checkpointPipebombsUsed;
	int m_checkpointBoomerBilesUsed;
	int m_checkpointAdrenalinesUsed;
	int m_checkpointDefibrillatorsUsed;
	int m_checkpointDamageTaken;
	int m_checkpointReviveOtherCount;
	int m_checkpointFirstAidShared;
	int m_checkpointIncaps;
	int m_checkpointAccuracy;
	int m_checkpointDeaths;
	int m_checkpointMeleeKills;
	int sBoomerKills;
	int sSmokerKills;
	int sJockeyKills;
	int sHunterKills;
	int sSpitterKills;
	int sChargerKills;

	// Pulled from database:
	int connections;
	int firstJoinedTime; // When user first joined server (first recorded statistics)
	int lastJoinedTime; // When the user last connected
	int joinedGameTime; // When user joined game session (not connected)

	ActiveWeaponData wpn;

	int idleStartTime;
	int totalIdleTime;

	// Map session tracking for stats_map_users
	int mapSessionStart;

	ArrayList pointsQueue;
	ArrayList pendingHeatmaps;

	void Init() {
		this.wpn.Init();
		this.pointsQueue = new ArrayList(3); // [ type, amount, time ]
		this.pendingHeatmaps = new ArrayList(sizeof(PendingHeatMapData));
	}

	void RecordHeatMap(HeatMapType type, const float pos[3]) {
		if(!hHeatmapActive.BoolValue || this.pendingHeatmaps == null) return;
		PendingHeatMapData hmd;
		hmd.timestamp = GetTime();
		hmd.type = type;
		int intPos[3];
		intPos[0] = RoundFloat(pos[0] / float(HEATMAP_POINT_SIZE)) * HEATMAP_POINT_SIZE;
		intPos[1] = RoundFloat(pos[1] / float(HEATMAP_POINT_SIZE)) * HEATMAP_POINT_SIZE;
		intPos[2] = RoundFloat(pos[2] / float(HEATMAP_POINT_SIZE)) * HEATMAP_POINT_SIZE;
		hmd.pos = intPos;
		this.pendingHeatmaps.PushArray(hmd);
	}

	void ResetFull() {
		this.steamid[0] = '\0';
		this.points = 0;
		this.idleStartTime = 0;
		this.totalIdleTime = 0;
		if(this.pointsQueue != null)
			this.pointsQueue.Clear();
		if(this.pendingHeatmaps != null) {
			this.pendingHeatmaps.Clear();
		}
		this.wpn.Reset(true);
	}

	void RecordPoint(PointRecordType type, int amount = 1) {
		this.points += amount;
		
		// STEAM ID-CENTRIC: Only proceed if we have a valid Steam ID
		if(strlen(this.steamid) < 8 || StrContains(this.steamid, "STEAM_") != 0) {
			LogError("[l4d2_stats_recorder] CRITICAL: RecordPoint called with invalid Steam ID: '%s' - points may be lost!", this.steamid);
			return; // Protect against corrupted data
		}
		
		PrintToServer("[l4d2_stats_recorder] RecordPoint: %s earned %d points (type: %d), total: %d", this.steamid, amount, type, this.points);
		
		// Queue ALL point types for database submission (including common kills)
		int index = this.pointsQueue.Push(type);
		this.pointsQueue.Set(index, amount, 1);
		this.pointsQueue.Set(index, GetTime(), 2);
		PrintToServer("[l4d2_stats_recorder] Queued point record: type=%d, amount=%d, queue size=%d", type, amount, this.pointsQueue.Length);
	}

	void MeasureDistance(int client) {
		// TODO: add guards (no noclip, must touch ground, survivor)
		// int timeDiff = GetTime() - this.distance.recordTime;
		if(!(GetEntityFlags(client) & FL_ONGROUND )) { return; }
		if(!IsPlayerAlive(client) || GetClientTeam(client) < 2) return;

		float pos[3];
		GetClientAbsOrigin(client, pos);
		this.distance.accumulation += GetVectorDistance(this.distance.lastPos, pos);
		this.distance.lastPos = pos;
		this.distance.recordTime = GetTime();
	}
}
Player players[MAXPLAYERS+1];
Game game;

#include <stats/heatmaps.sp>

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("Stats_GetPoints", Native_GetPoints);
	if(late) lateLoaded = true;
	return APLRes_Success;
}
//TODO: player_use (Check laser sights usage)
//TODO: Versus as infected stats
//TODO: Move kills to queue stats not on demand
//TODO: Track if lasers were had?

public void OnPluginStart() {
	EngineVersion g_Game = GetEngineVersion();
	if(g_Game != Engine_Left4Dead2) {
		SetFailState("This plugin is for L4D/L4D2 only.");	
	}
	
	// Initialize anti-abuse systems
	ResetHealCooldowns();
	if(!SQL_CheckConfig("stats")) {
		SetFailState("No database entry for 'stats'; no database to connect to.");
	} else if(!ConnectDB()) {
		SetFailState("Failed to connect to database.");
	}
	RunMigrations();

	g_rateMenu = SetupRateMenu();

	if(lateLoaded) {
		//If plugin late loaded, grab all real user's steamids again, then recreate user
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {
				char steamid[32];
				GetClientAuthId(i, AuthId_Steam2, steamid, sizeof(steamid));
				//Recreate user (grabs points, so it won't reset)
				SetupUserInDB(i, steamid);
			}
		}
	}

	hClownModeChangeChance = CreateConVar("l4d2_clown_mutate_chance", "0.3", "Percent chance of population changing", FCVAR_NONE, true, 0.0, true, 1.0);
	hClownMode = CreateConVar("l4d2_honk_mode", "0", "Shows a live clown honk count and increased shove amount.\n0 = OFF, 1 = ON, 2 = Randomly change population", FCVAR_NONE, true, 0.0, true, 2.0);
	hMinShove = FindConVar("z_gun_swing_coop_min_penalty");
	hMaxShove = FindConVar("z_gun_swing_coop_max_penalty");

	hClownMode.AddChangeHook(CVC_ClownModeChanged);

	hServerTags = CreateConVar("l4d2_statsrecorder_tags", "", "A comma-seperated list of tags that will be used to identity this server.");
	hServerTags.GetString(serverTags, sizeof(serverTags));
	hServerTags.AddChangeHook(CVC_TagsChanged);

	ConVar hGamemode = FindConVar("mp_gamemode");
	hGamemode.GetString(gamemode, sizeof(gamemode));
	hGamemode.AddChangeHook(CVC_GamemodeChange);

	hZDifficulty = FindConVar("z_difficulty");

	hHeatmapActive = CreateConVar("l4d2_statsrecorder_heatmaps_enabled", "0", "Should heatmap data be recorded? 1 for ON. Visualize heatmaps with /heatmaps", FCVAR_NONE, true, 0.1);
	hHeatmapInterval = CreateConVar("l4d2_statsrecorder_heatmap_interval", "60", "Determines how often position heatmaps are recorded in seconds.", FCVAR_NONE, true, 0.1);


	HookEvent("player_bot_replace", Event_PlayerEnterIdle);
	HookEvent("bot_player_replace", Event_PlayerLeaveIdle);
	//Hook all events to track statistics
	HookEvent("player_disconnect", Event_PlayerFullDisconnect);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_PlayerIncap);
	HookEvent("pills_used", Event_ItemUsed);
	HookEvent("defibrillator_used", Event_ItemUsed);
	HookEvent("adrenaline_used", Event_ItemUsed);
	HookEvent("heal_success", Event_ItemUsed);
	HookEvent("revive_success", Event_ItemUsed); //Yes it's not an item. No I don't care.
	HookEvent("melee_kill", Event_MeleeKill);
	HookEvent("tank_killed", Event_TankKilled);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("infected_death", Event_InfectedDeath);
	HookEvent("door_open", Event_DoorOpened);
	HookEvent("upgrade_pack_used", Event_UpgradePackUsed);
	HookEvent("triggered_car_alarm", Event_CarAlarm);
	//Used for campaign recording:
	HookEvent("finale_start", Event_FinaleStart);
	HookEvent("gauntlet_finale_start", Event_FinaleStart);
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
	HookEvent("finale_vehicle_ready", Event_FinaleVehicleReady);
	HookEvent("finale_win", Event_FinaleWin);
	HookEvent("hegrenade_detonate", Event_GrenadeDenonate);
	//Used to transition checkpoint statistics for stats_games
	HookEvent("game_init", Event_GameStart);
	HookEvent("round_end", Event_RoundEnd);

	HookEvent("boomer_exploded", Event_BoomerExploded);
	HookEvent("versus_round_start", Event_VersusRoundStart);
	HookEvent("map_transition", Event_MapTransition);
	HookEvent("player_ledge_grab", Event_LedgeGrab);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_left_safe_area", Event_PlayerLeftStartArea);
	AddNormalSoundHook(SoundHook);
	#if defined DEBUG
	RegConsoleCmd("sm_debug_stats", Command_DebugStats, "Debug stats");
	#endif
	RegAdminCmd("sm_stats", Command_PlayerStats, ADMFLAG_GENERIC);
	RegAdminCmd("sm_heatmaps", Command_Heatmaps, ADMFLAG_GENERIC);
	RegAdminCmd("sm_heatmap", Command_Heatmaps, ADMFLAG_GENERIC);
	RegAdminCmd("sm_debug_points", Command_CheckPlayerPoints, ADMFLAG_GENERIC, "Debug player point recording status");
	RegConsoleCmd("sm_rate", Command_RateMap);

	AutoExecConfig(true, "l4d2_stats_recorder");

	for(int i = 1; i <= MaxClients; i++) {
		players[i].Init();
	}

	
	CreateTimer(hHeatmapInterval.FloatValue, Timer_HeatMapInterval, _, TIMER_REPEAT);
	CreateTimer(DISTANCE_CALC_TIMER_INTERVAL, Timer_CalculateDistances, _, TIMER_REPEAT);
}

//When plugin is being unloaded: flush all user's statistics.
public void OnPluginEnd() {
	for(int i=1; i<=MaxClients;i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && players[i].steamid[0]) {
			FlushQueuedStats(i, false);
		}
	}
	ClearHeatMapEntities();
}

#define MAX_MIGRATIONS 1
char MIGRATIONS[MAX_MIGRATIONS][] = {
	"alter table stats_users add column if not exists total_distance_travelled float default 0 null"
};

void RunMigrations() {
	for(int i = 0; i < MAX_MIGRATIONS; i++) {
		g_db.Query(DBCT_Migration, MIGRATIONS[i], i);
	}
}
//////////////////////////////////
// TIMER
/////////////////////////////////
Action Timer_HeatMapInterval(Handle h) {
	// Skip recording any points when visualizing or escape vehicle ready
	if(!hHeatmapActive.BoolValue || game.finished || IsHeatMapVisualActive()) return Plugin_Continue;

	float pos[3];
	for(int i=1; i<=MaxClients;i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && players[i].steamid[0]) {
			MoveType moveType = GetEntityMoveType(i);
			if(moveType != MOVETYPE_WALK && moveType != MOVETYPE_LADDER) continue;
			GetClientAbsOrigin(i, pos);
			players[i].RecordHeatMap(HeatMap_Periodic, pos);
			if(players[i].pendingHeatmaps.Length > 25) {
				SubmitHeatmaps(i);
			}
		}
	}
	return Plugin_Continue;
}
Action Timer_CalculateDistances(Handle h) {
	if(game.finished) return Plugin_Continue;

	for(int i=1; i<= MaxClients;i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && players[i].steamid[0]) {
			MoveType moveType = GetEntityMoveType(i);
			if(moveType != MOVETYPE_WALK && moveType != MOVETYPE_LADDER) continue;
			players[i].MeasureDistance(i);
		}
	}
	return Plugin_Continue;
}

/////////////////////////////////
// CONVAR CHANGES
/////////////////////////////////
public void CVC_GamemodeChange(ConVar convar, const char[] oldValue, const char[] newValue) {
	strcopy(game.gamemode, sizeof(game.gamemode), newValue);
	strcopy(gamemode, sizeof(gamemode), newValue);
}
public void CVC_TagsChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	strcopy(serverTags, sizeof(serverTags), newValue);
}
public void CVC_ClownModeChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	hPopulationClowns = FindConVar("l4d2_population_clowns");
	if(hPopulationClowns == null) {
		PrintToServer("[Stats] ERROR: Missing plugin for clown mode");
		return;
	}
	if(hClownMode.IntValue > 0) {
		hMinShove.IntValue = 20;
		hMaxShove.IntValue = 40;
		hPopulationClowns.FloatValue = 0.4;
		hHonkCounterTimer = CreateTimer(15.0, Timer_HonkCounter, _, TIMER_REPEAT);
	} else {
		hMinShove.IntValue = 5;
		hMaxShove.IntValue = 15;
		hPopulationClowns.FloatValue = 0.0;
		if(hHonkCounterTimer != null) {
			delete hHonkCounterTimer;
		}
	}
}
public Action Timer_HonkCounter(Handle h) { 
	int honks, honker = -1;
	for(int j = 1; j <= MaxClients; j++) {
		if(players[j].clownsHonked > 0 && (players[j].clownsHonked > honks || honker == -1) && !IsFakeClient(j)) {
			honker = j;
			honks = players[j].clownsHonked;
		}
	}
	if(honker > 0) {
		for(int i = 1; i <= MaxClients; i++) {
			if(players[i].clownsHonked > 0 && IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2) {
				PrintHintText(i, "Top Honker: %N (%d honks)\nYou: %d honks", honker, honks, players[i].clownsHonked);
			}
		}
	}
	if(hClownMode.IntValue == 2 && GetURandomFloat() < hClownModeChangeChance.FloatValue) {
		if(GetRandomFloat() > 0.6)
			hPopulationClowns.FloatValue = 0.0;
		else 
			hPopulationClowns.FloatValue = GetRandomFloat();
		PrintToConsoleAll("Honk Mode: New population %.0f%%", hPopulationClowns.FloatValue * 100);
	}
	return Plugin_Continue; 
}
/////////////////////////////////
// PLAYER AUTH
/////////////////////////////////
public void OnClientAuthorized(int client, const char[] auth) {
	PrintToServer("[l4d2_stats_recorder] OnClientAuthorized: client=%d, auth='%s'", client, auth);
	
	if(client > 0 && !IsFakeClient(client)) {
		char steamid[32];
		strcopy(steamid, sizeof(steamid), auth);
		PrintToServer("[l4d2_stats_recorder] Processing authorization for %N (client %d)", client, client);
		SetupUserInDB(client, steamid);
	} else {
		if(client <= 0) {
			PrintToServer("[l4d2_stats_recorder] OnClientAuthorized: Invalid client ID %d", client);
		} else if(IsFakeClient(client)) {
			PrintToServer("[l4d2_stats_recorder] OnClientAuthorized: Client %d is fake client (bot), skipping", client);
		}
	}
}
public void OnClientPutInServer(int client) {
	if(!IsFakeClient(client)) {
		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	}
}
public void OnClientDisconnect(int client) {
	//Check if any pending stats to send.
	if(!IsFakeClient(client) && IsClientInGame(client)) {
		//Record campaign session, incase they leave early. 
		//Should only fire if disconnects after escape_vehicle_ready and before finale_win (credits screen)
		if(game.finished && game.uuid[0] && players[client].steamid[0]) {
			IncrementSessionStat(client);
			RecordCampaign(client);
			IncrementBothStats(client, "finales_won", 1);
			players[client].RecordPoint(PType_FinishCampaign, 1000);
		}
		
		// Handle tank disconnection
		if(g_bTankInPlay && g_iTankClient == client) {
			// Try to find if tank passed to another player
			int newTankClient = FindTankClient();
			if(newTankClient > 0) {
				g_iTankClient = newTankClient;
				g_iTankHealth = GetClientHealth(newTankClient);
				#if defined DEBUG
				PrintToServer("[DEBUG] Tank passed to client %d", newTankClient);
				#endif
			} else {
				// Tank disconnected without passing, reset tracking
				g_bTankInPlay = false;
				g_iTankClient = 0;
				g_iTankHealth = 0;
				#if defined DEBUG
				PrintToServer("[DEBUG] Tank disconnected, resetting tracking");
				#endif
			}
		}

		FlushQueuedStats(client, true);
		players[client].ResetFull();

		//ResetSessionStats(client); //Can't reset session stats cause transitions!
	}
}

void Event_PlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0) {
		players[client].joinedGameTime = GetTime();
	}
}

void Event_PlayerFullDisconnect(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0) {
		players[client].ResetFull();
	}
}

void Event_PlayerEnterIdle(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("player"));
	if(client > 0) {
		players[client].idleStartTime = GetTime();
	}
}

void Event_PlayerLeaveIdle(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("player"));
	if(client > 0 && players[client].idleStartTime > 0) {
		players[client].idleStartTime = 0;
		players[client].totalIdleTime = GetTime() - players[client].idleStartTime;
	}
}

///////////////////////////////////
//DB METHODS
//////////////////////////////////

bool ConnectDB() {
	char error[255];
	g_db = SQL_Connect("stats", true, error, sizeof(error));
	if (g_db == null) {
		LogError("Database error %s", error);
		delete g_db;
		return false;
	} else {
		PrintToServer("Connected to database stats");
		SQL_LockDatabase(g_db);
		SQL_FastQuery(g_db, "SET NAMES \"UTF8mb4\"");  
		SQL_UnlockDatabase(g_db);
		g_db.SetCharset("utf8mb4");
		return true;
	}
}
//Setups a user, this tries to fetch user by steamid
void SetupUserInDB(int client, const char steamid[32]) {
	if(client > 0 && !IsFakeClient(client)) {
		// Validate Steam ID format
		if(strlen(steamid) < 8 || StrContains(steamid, "STEAM_") != 0) {
			LogError("[l4d2_stats_recorder] Invalid Steam ID format for client %d: '%s'", client, steamid);
			PrintToServer("[l4d2_stats_recorder] ERROR: Invalid Steam ID format for %N: '%s'", client, steamid);
			return;
		}
		
		players[client].ResetFull();

		strcopy(players[client].steamid, 32, steamid);
		players[client].startedPlaying = GetTime();
		
		// Initialize map session tracking
		players[client].mapSessionStart = GetTime();
		
		PrintToServer("[l4d2_stats_recorder] Setting up user %N with Steam ID: %s", client, steamid);
		
		char query[256];
		char escapedSteamId[64];
		g_db.Escape(steamid, escapedSteamId, sizeof(escapedSteamId));
		
		// TODO: 	connections, first_join last_join
		Format(query, sizeof(query), "SELECT last_alias,points,connections,created_date,last_join_date FROM stats_users WHERE steamid='%s'", escapedSteamId);
		SQL_TQuery(g_db, DBCT_CheckUserExistance, query, GetClientUserId(client));
	}
}
//Increments a statistic by X amount
void IncrementStat(int client, const char[] name, int amount = 1, bool lowPriority = true) {
	if(client > 0 && !IsFakeClient(client) && IsClientConnected(client)) {
		//Only run if client valid client, AND has steamid. Not probably necessarily anymore.
		if (players[client].steamid[0]) {
			if(g_db == INVALID_HANDLE) {
				LogError("Database handle is invalid.");
				return;
			}
			int escaped_name_size = 2*strlen(name)+1;
			char[] escaped_name = new char[escaped_name_size];
			char query[255];
			g_db.Escape(name, escaped_name, escaped_name_size);
			Format(query, sizeof(query), "UPDATE stats_users SET `%s`=`%s`+%d WHERE steamid='%s'", escaped_name, escaped_name, amount, players[client].steamid);
			#if defined DEBUG
			PrintToServer("[Debug] Updating Stat %s (+%d) for %N (%d) [%s]", name, amount, client, client, players[client].steamid);
			#endif 
			SQL_TQuery(g_db, DBCT_Generic, query, QUERY_UPDATE_STAT, lowPriority ? DBPrio_Low : DBPrio_Normal);
		}
	}
}

//Increments both lifetime and map-specific statistics
void IncrementBothStats(int client, const char[] name, int amount = 1, bool lowPriority = true) {
	IncrementStat(client, name, amount, lowPriority);    // Lifetime stats
	IncrementMapStat(client, name, amount, lowPriority); // Map-specific stats
}

//Increments a map-specific statistic for stats_map_users table
void IncrementMapStat(int client, const char[] name, int amount = 1, bool lowPriority = true) {
	if(client > 0 && !IsFakeClient(client) && IsClientConnected(client)) {
		if (players[client].steamid[0] && game.mapId[0] && players[client].mapSessionStart > 0) {
			if(g_db == INVALID_HANDLE) {
				LogError("Database handle is invalid.");
				return;
			}
			int escaped_name_size = 2*strlen(name)+1;
			char[] escaped_name = new char[escaped_name_size];
			char query[512];
			g_db.Escape(name, escaped_name, escaped_name_size);
			
			// Insert or update the map session stats
			// For insert, we need to get user data from stats_users first
			Format(query, sizeof(query), 
				"INSERT INTO stats_map_users (steamid, mapid, session_start, last_alias, last_join_date, created_date, country, %s, session_end) " ...
				"SELECT '%s', '%s', %d, last_alias, last_join_date, created_date, country, %d, UNIX_TIMESTAMP() " ...
				"FROM stats_users WHERE steamid = '%s' " ...
				"ON DUPLICATE KEY UPDATE stats_map_users.%s = stats_map_users.%s + %d, session_end = UNIX_TIMESTAMP()",
				escaped_name, players[client].steamid, game.mapId, players[client].mapSessionStart, amount, players[client].steamid,
				escaped_name, escaped_name, amount);
			
			#if defined DEBUG
			PrintToServer("[Debug] Updating Map Stat %s (+%d) for %N on map %s [%s]", name, amount, client, game.mapId, players[client].steamid);
			#endif 
			SQL_TQuery(g_db, DBCT_Generic, query, QUERY_UPDATE_STAT, lowPriority ? DBPrio_Low : DBPrio_Normal);
		}
	}
}

void GetTopWeapon(int client, char[] buffer, int maxlen) {
	buffer[0] = '\0';
	
	if(players[client].wpn.pendingStats == null || players[client].wpn.pendingStats.Size == 0) {
		return;
	}
	
	// Also check the current weapon
	if(players[client].wpn.classname[0] != '\0') {
		WeaponStatistics stats;
		players[client].wpn.pendingStats.GetArray(players[client].wpn.classname, stats, sizeof(stats));
		stats.minutesUsed += (GetTime() - players[client].wpn.pickupTime);
		players[client].wpn.pendingStats.SetArray(players[client].wpn.classname, stats, sizeof(stats));
	}
	
	StringMapSnapshot snapshot = players[client].wpn.pendingStats.Snapshot();
	char weaponName[64];
	char topWeaponName[64];
	float maxTime = 0.0;
	WeaponStatistics stats;
	
	for(int i = 0; i < snapshot.Length; i++) {
		snapshot.GetKey(i, weaponName, sizeof(weaponName));
		players[client].wpn.pendingStats.GetArray(weaponName, stats, sizeof(stats));
		
		if(stats.minutesUsed > maxTime) {
			maxTime = stats.minutesUsed;
			strcopy(topWeaponName, sizeof(topWeaponName), weaponName);
		}
	}
	
	delete snapshot;
	
	if(topWeaponName[0] != '\0') {
		strcopy(buffer, maxlen, topWeaponName);
	}
}

void RecordCampaign(int client) {
	if (client > 0 && IsClientInGame(client)) {
		char query[1023];

		if(players[client].m_checkpointZombieKills == 0) {
			PrintToServer("Warn: Client %N for %s | 0 zombie kills", client, game.uuid);
		}

		char model[64];
		GetClientModel(client, model, sizeof(model));

		// Get the most used weapon
		char topWeapon[64];
		GetTopWeapon(client, topWeapon, sizeof(topWeapon));

		int ping = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iPing", _, client);
		if(ping < 0) ping = 0;

		int finaleTimeTotal = (game.finaleStartTime > 0) ? GetTime() - game.finaleStartTime : 0;
		Format(query, sizeof(query), "INSERT INTO stats_games (`steamid`, `map`, `gamemode`,`campaignID`, `finale_time`, `join_time`,`date_start`,`date_end`, `zombieKills`, `survivorDamage`, `MedkitsUsed`, `PillsUsed`, `MolotovsUsed`, `PipebombsUsed`, `BoomerBilesUsed`, `AdrenalinesUsed`, `DefibrillatorsUsed`, `DamageTaken`, `ReviveOtherCount`, `FirstAidShared`, `Incaps`, `Deaths`, `MeleeKills`, `difficulty`, `ping`,`boomer_kills`,`smoker_kills`,`jockey_kills`,`hunter_kills`,`spitter_kills`,`charger_kills`,`server_tags`,`characterType`,`honks`,`top_weapon`, `SurvivorFFCount`, `SurvivorFFTakenCount`, `SurvivorFFDamage`, `SurvivorFFTakenDamage`) VALUES ('%s','%s','%s','%s',%d,%d,%d,UNIX_TIMESTAMP(),%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,'%s',%d,%d,'%s',%d,%d,%d,%d)",
			players[client].steamid,
			game.mapId,
			gamemode,
			game.uuid,
			finaleTimeTotal,
			players[client].joinedGameTime,
			game.startTime > 0 ? game.startTime : game.finaleStartTime, //incase iGameStartTime not set: use finaleTimeStart
			//unix_timestamp(),
			players[client].m_checkpointZombieKills,
			players[client].m_checkpointSurvivorDamage,
			players[client].m_checkpointMedkitsUsed,
			players[client].m_checkpointPillsUsed,
			players[client].m_checkpointMolotovsUsed,
			players[client].m_checkpointPipebombsUsed,
			players[client].m_checkpointBoomerBilesUsed,
			players[client].m_checkpointAdrenalinesUsed,
			players[client].m_checkpointDefibrillatorsUsed,
			players[client].m_checkpointDamageTaken,
			players[client].m_checkpointReviveOtherCount,
			players[client].m_checkpointFirstAidShared,
			players[client].m_checkpointIncaps,
			players[client].m_checkpointDeaths,
			players[client].m_checkpointMeleeKills,
			game.difficulty,
			ping, //record user ping
			players[client].sBoomerKills,
			players[client].sSmokerKills,
			players[client].sJockeyKills,
			players[client].sHunterKills,
			players[client].sSpitterKills,
			players[client].sChargerKills,
			serverTags,
			GetSurvivorType(model),
			players[client].clownsHonked,
			topWeapon,
			players[client].damageSurvivorFFCount, //SurvivorFFCount
			players[client].damageFFTakenCount, //SurvivorFFTakenCount
			players[client].damageSurvivorFF, //SurvivorFFDamage
			players[client].damageFFTaken //SurvivorFFTakenDamage
		);
		SQL_LockDatabase(g_db);
		bool result = SQL_FastQuery(g_db, query);
		SQL_UnlockDatabase(g_db);
		if(!result) {
			char error[128];
			SQL_GetError(g_db, error, sizeof(error));
			LogError("[l4d2_stats_recorder] RecordCampaign for %d failed. UUID %s | Query: `%s` | Error: %s", game.uuid, client, query, error);
		}
	}
}
//Flushes all the tracked statistics, and runs UPDATE SQL query on user. Then resets the variables to 0
void FlushQueuedStats(int client, bool disconnect) {
	//Update stats (don't bother checking if 0.)
	int minutes_played = (GetTime() - players[client].startedPlaying) / 60;
	//Incase somehow startedPlaying[client] not set (plugin reloaded?), defualt to 0
	if(minutes_played >= 2147483645) {
		players[client].startedPlaying = GetTime();
		minutes_played = 0;
	}
	//Always record stats if the player has played for at least 1 minute or has any meaningful activity
	//This prevents data loss for players who don't earn points but still participate
	//FIXED: Include players with 0 or negative points in stats updates
	if(minutes_played > 0 || players[client].points != 0 ||
	   GetEntProp(client, Prop_Send, "m_checkpointZombieKills") > 0 ||
	   GetEntProp(client, Prop_Send, "m_checkpointDamageTaken") > 0 ||
	   GetEntProp(client, Prop_Send, "m_checkpointReviveOtherCount") > 0 ||
	   players[client].damageSurvivorGiven > 0 ||
	   players[client].doorOpens > 0) {
		char query[1023];
		Format(query, sizeof(query), "UPDATE stats_users SET survivor_damage_give=survivor_damage_give+%d,survivor_damage_rec=survivor_damage_rec+%d, infected_damage_give=infected_damage_give+%d,infected_damage_rec=infected_damage_rec+%d,survivor_ff=survivor_ff+%d,survivor_ff_rec=survivor_ff_rec+%d,common_kills=common_kills+%d,common_headshots=common_headshots+%d,melee_kills=melee_kills+%d,door_opens=door_opens+%d,damage_to_tank=damage_to_tank+%d, damage_witch=damage_witch+%d,minutes_played=minutes_played+%d, kills_witch=kills_witch+%d,points=%d,packs_used=packs_used+%d,damage_molotov=damage_molotov+%d,kills_molotov=kills_molotov+%d,kills_pipe=kills_pipe+%d,kills_minigun=kills_minigun+%d,clowns_honked=clowns_honked+%d,total_distance_travelled=total_distance_travelled+%d WHERE steamid='%s'",
			//VARIABLE													//COLUMN NAME

			players[client].damageSurvivorGiven, 						//survivor_damage_give
			GetEntProp(client, Prop_Send, "m_checkpointDamageTaken"),   //survivor_damage_rec
			players[client].damageInfectedGiven,  						//infected_damage_give
			players[client].damageInfectedRec,   						//infected_damage_rec
			players[client].damageSurvivorFF,    						//survivor_ff
			players[client].damageFFTaken,								//survivor_ff_rec
			GetEntProp(client, Prop_Send, "m_checkpointZombieKills"), 	//common_kills
			GetEntProp(client, Prop_Send, "m_checkpointHeadshots"),   	//common_headshots
			GetEntProp(client, Prop_Send, "m_checkpointMeleeKills"),  	//melee_kills
			players[client].doorOpens, 									//door_opens
			GetEntProp(client, Prop_Send, "m_checkpointDamageToTank"),  //damage_to_tank
			GetEntProp(client, Prop_Send, "m_checkpointDamageToWitch"), //damage_witch
			minutes_played, 											//minutes_played
			players[client].witchKills, 								//kills_witch
			players[client].points, 									//points
			players[client].upgradePacksDeployed, 						//packs_used
			players[client].molotovDamage, 								//damage_molotov
			players[client].pipeKills, 									//kills_pipe,
			players[client].molotovKills,								//kills_molotov
			players[client].minigunKills,								//kills_minigun
			players[client].clownsHonked,								//clowns_honked
			players[client].distance.accumulation,						//total_distance_travelled
			players[client].steamid[0]
		);
		
		//If disconnected, can't put on another thread for some reason: Push it out fast
		PrintToServer("[l4d2_stats_recorder] Flushing stats for %N (SteamID: %s, Points: %d, Queue size: %d)", 
			client, players[client].steamid, players[client].points, players[client].pointsQueue.Length);
			
		if(disconnect) {
			SQL_LockDatabase(g_db);
			SQL_FastQuery(g_db, query);
			SQL_UnlockDatabase(g_db);
			ResetInternal(client, true);
		}else{
			SQL_TQuery(g_db, DBCT_FlushQueuedStats, query, GetClientUserId(client));
			SubmitPoints(client);
			SubmitWeaponStats(client);
			SubmitHeatmaps(client);
		}
	}
}

void SubmitPoints(int client) {
	// Check database connection
	if(g_db == null) {
		LogError("[l4d2_stats_recorder] Database not connected. Cannot submit points for client %d", client);
		return;
	}
	
	// Validate Steam ID before submitting
	if(strlen(players[client].steamid) < 8 || StrContains(players[client].steamid, "STEAM_") != 0) {
		LogError("[l4d2_stats_recorder] Invalid Steam ID for client %d: '%s'. Points not submitted.", client, players[client].steamid);
		return;
	}
	
	// Submit points regardless of queue length - important for players with 0 or negative points
	if(players[client].pointsQueue.Length > 0) {
		// CRITICAL FIX: Ensure user exists before submitting points
		// Use INSERT IGNORE to create user if not exists, then submit points
		char setupQuery[512];
		Format(setupQuery, sizeof(setupQuery), 
			"INSERT IGNORE INTO stats_users (steamid, last_alias, created_date, last_join_date, points) VALUES ('%s', 'TempUser', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0)",
			players[client].steamid);
		SQL_TQuery(g_db, DBCT_EnsureUserExists, setupQuery, GetClientUserId(client));
	} else {
		PrintToServer("[l4d2_stats_recorder] No queued points for %s, but ensuring user exists", players[client].steamid);
		// Still ensure user exists even with no points to queue
		char setupQuery[512];
		Format(setupQuery, sizeof(setupQuery), 
			"INSERT IGNORE INTO stats_users (steamid, last_alias, created_date, last_join_date, points) VALUES ('%s', 'TempUser', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0)",
			players[client].steamid);
		SQL_TQuery(g_db, DBCT_EnsureUserExists, setupQuery, GetClientUserId(client));
	}
}

// New function to actually submit points after ensuring user exists
void SubmitPointsNow(int client) {
	if(players[client].pointsQueue.Length > 0) {
		char query[4098];
		char escapedSteamId[64];
		g_db.Escape(players[client].steamid, escapedSteamId, sizeof(escapedSteamId));
		
		Format(query, sizeof(query), "INSERT INTO stats_points (steamid,type,amount,timestamp) VALUES ");
		for(int i = 0; i < players[client].pointsQueue.Length; i++) {
			int type = players[client].pointsQueue.Get(i, 0);
			int amount = players[client].pointsQueue.Get(i, 1);
			int timestamp = players[client].pointsQueue.Get(i, 2);
			Format(query, sizeof(query), "%s('%s',%d,%d,%d)%c",
				query,
				escapedSteamId,
				type,
				amount,
				timestamp,
				i == players[client].pointsQueue.Length - 1 ? ';' : ',' // Semicolon on last entry
			);
		}
		SQL_TQuery(g_db, DBCT_SubmitPoints, query, GetClientUserId(client), DBPrio_Low);
		// Don't clear the queue here - wait for confirmation
	}
}

void SubmitWeaponStats(int client) {
	if(players[client].wpn.pendingStats != null && players[client].wpn.pendingStats.Size > 0) {
		// Force save weapon stats, instead of waiting for player to switch weapon
		char query[512], weapon[64];
		
		StringMapSnapshot snapshot = players[client].wpn.pendingStats.Snapshot();
		WeaponStatistics stats;
		for(int i = 0; i < snapshot.Length; i++) {
			snapshot.GetKey(i, weapon, sizeof(weapon));
			if(weapon[0] == '\0') continue;
			players[client].wpn.pendingStats.GetArray(weapon, stats, sizeof(stats));
			if(stats.minutesUsed == 0) continue;
			g_db.Format(query, sizeof(query), 
				"INSERT INTO stats_weapons_usage (steamid,weapon,minutesUsed,totalDamage,kills,headshots) VALUES ('%s','%s',%f,%d,%d,%d) ON DUPLICATE KEY UPDATE minutesUsed=minutesUsed+%f,totalDamage=totalDamage+%d,kills=kills+%d,headshots=headshots+%d",
				players[client].steamid,
				weapon,
				stats.minutesUsed,
				stats.totalDamage,
				stats.kills,
				stats.headshots,
				stats.minutesUsed,
				stats.totalDamage,
				stats.kills,
				stats.headshots
			);
			g_db.Query(DBCT_Generic, query, QUERY_WEAPON_STATS, DBPrio_Low);
		}
	}
} 

void SubmitHeatmaps(int client) {
	if(players[client].pendingHeatmaps != null && players[client].pendingHeatmaps.Length > 0) {
		PendingHeatMapData hmd;
		char query[2048];
		Format(query, sizeof(query), "INSERT INTO stats_heatmaps (steamid,map,timestamp,type,x,y,z) VALUES ");
		int length = players[client].pendingHeatmaps.Length;
		char commaChar = ',';
		for(int i = 0; i < length; i++) {
			players[client].pendingHeatmaps.GetArray(i, hmd);
			// Add commas to every entry but trailing
			if(i == length - 1) {
				commaChar = ' ';
			}
			Format(query, sizeof(query), "%s('%s','%s',%d,%d,%d,%d,%d)%c", 
				query,
				players[client].steamid,
				game.mapId, //map nam
				hmd.timestamp,
				hmd.type,
				hmd.pos[0],
				hmd.pos[1],
				hmd.pos[2],
				commaChar
			);
		}

		SQL_TQuery(g_db, DBCT_Generic, query, QUERY_HEATMAPS, DBPrio_Low);
		// Resize using the new length - old length, incase new data shows up.
		players[client].pendingHeatmaps.Erase(length-1);
	}
}

//Record a special kill to local variable
void IncrementSpecialKill(int client, int special) {
	switch(special) {
		case 1: players[client].sSmokerKills++;
		case 2: players[client].sBoomerKills++;
		case 3: players[client].sHunterKills++;
		case 4: players[client].sSpitterKills++;
		case 5: players[client].sJockeyKills++;
		case 6: players[client].sChargerKills++;
	}
}
//Called ONLY on game_start
void ResetSessionStats(int client, bool resetAll) {
	players[client].m_checkpointZombieKills =			0;
	players[client].m_checkpointSurvivorDamage = 		0;
	players[client].m_checkpointMedkitsUsed = 			0;
	players[client].m_checkpointPillsUsed = 			0;
	players[client].m_checkpointMolotovsUsed = 			0;
	players[client].m_checkpointPipebombsUsed = 		0;
	players[client].m_checkpointBoomerBilesUsed = 		0;
	players[client].m_checkpointAdrenalinesUsed = 		0;
	players[client].m_checkpointDefibrillatorsUsed = 	0;
	players[client].m_checkpointDamageTaken =			0;
	players[client].m_checkpointReviveOtherCount = 		0;
	players[client].m_checkpointFirstAidShared = 		0;
	players[client].m_checkpointIncaps  = 				0;
	if(resetAll) players[client].m_checkpointDeaths = 	0;
	players[client].m_checkpointMeleeKills = 			0;
	players[client].sBoomerKills  = 0;
	players[client].sSmokerKills  = 0;
	players[client].sJockeyKills  = 0;
	players[client].sHunterKills  = 0;
	players[client].sSpitterKills = 0;
	players[client].sChargerKills = 0;
	players[client].clownsHonked  = 0;

	players[client].damageSurvivorFF 		= 0;
	players[client].damageFFTaken 			= 0;
	players[client].damageSurvivorFFCount   = 0;
	players[client].damageFFTakenCount 		= 0;
}
//Called via FlushQueuedStats which is called on disconnects / map transitions / game_start or round_end
void ResetInternal(int client, bool disconnect) {
	players[client].damageSurvivorGiven 	= 0;
	players[client].doorOpens 				= 0;
	players[client].witchKills 				= 0;
	players[client].upgradePacksDeployed 	= 0;
	players[client].molotovDamage 			= 0;
	players[client].pipeKills 				= 0;
	players[client].molotovKills 			= 0;
	players[client].minigunKills 			= 0;
	if(!disconnect) {
		players[client].startedPlaying = GetTime();
	}
	players[client].wpn.Flush();
}
void IncrementSessionStat(int client) {
	players[client].m_checkpointZombieKills += 			GetEntProp(client, Prop_Send, "m_checkpointZombieKills");
	players[client].m_checkpointSurvivorDamage += 		players[client].damageSurvivorFF;
	players[client].m_checkpointMedkitsUsed += 			GetEntProp(client, Prop_Send, "m_checkpointMedkitsUsed");
	players[client].m_checkpointPillsUsed += 			GetEntProp(client, Prop_Send, "m_checkpointPillsUsed");
	players[client].m_checkpointMolotovsUsed += 		GetEntProp(client, Prop_Send, "m_checkpointMolotovsUsed");
	players[client].m_checkpointPipebombsUsed += 		GetEntProp(client, Prop_Send, "m_checkpointPipebombsUsed");
	players[client].m_checkpointBoomerBilesUsed += 		GetEntProp(client, Prop_Send, "m_checkpointBoomerBilesUsed");
	players[client].m_checkpointAdrenalinesUsed += 		GetEntProp(client, Prop_Send, "m_checkpointAdrenalinesUsed");
	players[client].m_checkpointDefibrillatorsUsed += 	GetEntProp(client, Prop_Send, "m_checkpointDefibrillatorsUsed");
	players[client].m_checkpointDamageTaken +=			GetEntProp(client, Prop_Send, "m_checkpointDamageTaken");
	players[client].m_checkpointReviveOtherCount += 	GetEntProp(client, Prop_Send, "m_checkpointReviveOtherCount");
	players[client].m_checkpointFirstAidShared += 		GetEntProp(client, Prop_Send, "m_checkpointFirstAidShared");
	players[client].m_checkpointIncaps  += 				GetEntProp(client, Prop_Send, "m_checkpointIncaps");
	players[client].m_checkpointDeaths += 				GetEntProp(client, Prop_Send, "m_checkpointDeaths");
	players[client].m_checkpointMeleeKills += 			GetEntProp(client, Prop_Send, "m_checkpointMeleeKills");
	PrintToServer("[l4d2_stats_recorder] Incremented checkpoint stats for %N", client);
}

/////////////////////////////////
//DATABASE CALLBACKS
/////////////////////////////////
//Handles the CreateDBUser() response. Either updates alias and stores points, or creates new SQL user.
public void DBCT_CheckUserExistance(Handle db, DBResultSet results, const char[] error, any data) {
	if(db == INVALID_HANDLE || results == INVALID_HANDLE) {
		LogError("DBCT_CheckUserExistance returned error: %s", error);
		// CRITICAL: If user lookup fails, try to ensure user exists anyway
		int client = GetClientOfUserId(data);
		if(client > 0 && IsClientInGame(client) && strlen(players[client].steamid) > 0) {
			PrintToServer("[l4d2_stats_recorder] User lookup failed for %N (%s), attempting emergency user creation", 
				client, players[client].steamid);
			
			char emergencyQuery[512];
			Format(emergencyQuery, sizeof(emergencyQuery), 
				"INSERT IGNORE INTO stats_users (steamid, last_alias, created_date, last_join_date, points) VALUES ('%s', 'EmergencyUser', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0)",
				players[client].steamid);
			SQL_TQuery(g_db, DBCT_EmergencyUserCreation, emergencyQuery, GetClientUserId(client));
		}
		return;
	}
	//initialize variables
	int client = GetClientOfUserId(data); 
	if(client == 0) return;
	int alias_length = 2*MAX_NAME_LENGTH+1;
	char alias[MAX_NAME_LENGTH], ip[40], country_name[45];
	char[] safe_alias = new char[alias_length];

	//Get a SQL-safe player name, and their country and IP
	GetClientName(client, alias, sizeof(alias));
	
	// CRITICAL FIX: Never block user setup due to name issues - use fallback
	if(strlen(alias) == 0) {
		// Generate fallback name from Steam ID
		char steamid_short[16];
		strcopy(steamid_short, sizeof(steamid_short), players[client].steamid[8]); // Skip "STEAM_0:"
		Format(alias, sizeof(alias), "Player_%s", steamid_short);
		LogMessage("[l4d2_stats_recorder] Using fallback name for player %d: '%s' (SteamID: %s)", 
			client, alias, players[client].steamid);
	}
	
	PrintToServer("[l4d2_stats_recorder] Processing player %N with name '%s' (length: %d, SteamID: %s)", 
		client, alias, strlen(alias), players[client].steamid);
		
	SQL_EscapeString(g_db, alias, safe_alias, alias_length);
	GetClientIP(client, ip, sizeof(ip));
	GeoipCountry(ip, country_name, sizeof(country_name));

	char query[255]; 
	if(results.RowCount == 0) {
		//user does not exist in db, create now
		Format(query, sizeof(query), "INSERT INTO `stats_users` (`steamid`, `last_alias`, `last_join_date`,`created_date`,`country`) VALUES ('%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), '%s')", players[client].steamid, safe_alias, country_name);
		g_db.Query(DBCT_Generic, query, QUERY_UPDATE_USER);

		Format(query, sizeof(query), "%N is joining for the first time", client);
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID) {
				PrintToChat(i, query);
			}
		}
		PrintToServer("[l4d2_stats_recorder] Created new database entry for %N (%s)", client, players[client].steamid);
	} else {
		//User does exist, check if alias is outdated and update some columns (last_join_date, country, connections, or last_alias)
		results.FetchRow();
		char prevName[32];
		// last_alias,points,connections,created_date,last_join_date
		results.FetchString(0, prevName, sizeof(prevName));
		players[client].points = results.FetchInt(1);
		players[client].connections = results.FetchInt(2);
		players[client].firstJoinedTime = results.FetchInt(3);
		players[client].lastJoinedTime = results.FetchInt(4);
		
		PrintToServer("[l4d2_stats_recorder] Existing user %N: alias='%s', prev='%s', points=%d", 
			client, safe_alias, prevName, players[client].points);

		if(players[client].points == 0) {
			PrintToServer("[l4d2_stats_recorder] Warning: Existing player %N (%s) has 0 points in database", client, players[client].steamid);
			// Check if there are orphaned point records
			char checkQuery[256];
			Format(checkQuery, sizeof(checkQuery), "SELECT COUNT(*) as count, SUM(amount) as total FROM stats_points WHERE steamid='%s'", players[client].steamid);
			SQL_TQuery(g_db, DBCT_CheckOrphanedPoints, checkQuery, GetClientUserId(client));
		} else {
			PrintToServer("[l4d2_stats_recorder] Player %N (%s) loaded with %d points", client, players[client].steamid, players[client].points);
		}
		int connections_amount = lateLoaded ? 0 : 1;

		Format(query, sizeof(query), "UPDATE `stats_users` SET `last_alias`='%s', `last_join_date`=UNIX_TIMESTAMP(), `country`='%s', connections=connections+%d WHERE `steamid`='%s'", safe_alias, country_name, connections_amount, players[client].steamid);
		g_db.Query(DBCT_Generic, query, QUERY_UPDATE_USER);
		if(!StrEqual(prevName, alias)) {
			// Add prev name to history - NON-BLOCKING: Name history is for display only
			PrintToServer("[l4d2_stats_recorder] Adding name '%s' -> '%s' to history for %N (SteamID: %s)", 
				prevName, safe_alias, client, players[client].steamid);
			g_db.Format(query, sizeof(query), "INSERT INTO user_names_history (steamid, name, created) VALUES ('%s','%s', UNIX_TIMESTAMP())", players[client].steamid, safe_alias);
			g_db.Query(DBCT_NameHistoryUpdate, query, GetClientUserId(client));
		}
	}
}
//Generic database response that logs error
void DBCT_Generic(Handle db, Handle child, const char[] error, queryType data) {
	if(db == null || child == null) {
		if(data != QUERY_ANY) {
			LogError("DBCT_Generic query `%s` returned error: %s", QUERY_TYPE_ID[data], error);
			if(data == QUERY_POINTS) {
				PrintToServer("[l4d2_stats_recorder] ERROR: Failed to submit points to database!");
			} else if(data == QUERY_UPDATE_NAME_HISTORY) {
				PrintToServer("[l4d2_stats_recorder] ERROR: Failed to insert name history - this could affect user setup!");
			} else if(data == QUERY_UPDATE_USER) {
				PrintToServer("[l4d2_stats_recorder] ERROR: Failed to update user info - this could prevent point recording!");
			}
		} else {
			LogError("DBCT_Generic returned error: %s", error);
		}
	}
}

void DBCT_SubmitPoints(Handle db, Handle child, const char[] error, int userid) {
	int client = GetClientOfUserId(userid);
	if(db == null || child == null) {
		LogError("[l4d2_stats_recorder] Failed to submit points: %s", error);
		PrintToServer("[l4d2_stats_recorder] ERROR: Failed to submit points for client %d!", client);
		// Don't clear the queue on error - retry later
	} else {
		// Success - clear the queue
		if(client > 0 && IsClientInGame(client)) {
			players[client].pointsQueue.Clear();
		}
	}
}

void DBCT_CheckOrphanedPoints(Handle db, Handle results, const char[] error, int userid) {
	int client = GetClientOfUserId(userid);
	if(client <= 0 || !IsClientInGame(client)) return;
	
	if(db == null || results == null) {
		LogError("[l4d2_stats_recorder] Failed to check orphaned points: %s", error);
		return;
	}
	
	if(SQL_FetchRow(results)) {
		int count = SQL_FetchInt(results, 0);
		int total = SQL_IsFieldNull(results, 1) ? 0 : SQL_FetchInt(results, 1);
		
		if(count > 0) {
			PrintToServer("[l4d2_stats_recorder] Found %d orphaned point records for %N (%s) totaling %d points!", 
				count, client, players[client].steamid, total);
			
			// Fix the points total
			if(total != 0) {
				char fixQuery[256];
				Format(fixQuery, sizeof(fixQuery), "UPDATE stats_users SET points=(SELECT COALESCE(SUM(amount),0) FROM stats_points WHERE steamid='%s') WHERE steamid='%s'", 
					players[client].steamid, players[client].steamid);
				SQL_TQuery(g_db, DBCT_FixPoints, fixQuery, GetClientUserId(client));
			}
		}
	}
}

void DBCT_FixPoints(Handle db, Handle child, const char[] error, int userid) {
	int client = GetClientOfUserId(userid);
	if(db == null || child == null) {
		LogError("[l4d2_stats_recorder] Failed to fix points: %s", error);
	} else {
		if(client > 0 && IsClientInGame(client)) {
			// Reload player points
			char query[256];
			Format(query, sizeof(query), "SELECT points FROM stats_users WHERE steamid='%s'", players[client].steamid);
			SQL_TQuery(g_db, DBCT_ReloadPoints, query, GetClientUserId(client));
		}
	}
}

void DBCT_ReloadPoints(Handle db, Handle results, const char[] error, int userid) {
	int client = GetClientOfUserId(userid);
	if(client <= 0 || !IsClientInGame(client)) return;
	
	if(db == null || results == null) {
		LogError("[l4d2_stats_recorder] Failed to reload points: %s", error);
		return;
	}
	
	if(SQL_FetchRow(results)) {
		int oldPoints = players[client].points;
		players[client].points = SQL_FetchInt(results, 0);
		PrintToServer("[l4d2_stats_recorder] Fixed points for %N (%s): %d -> %d", 
			client, players[client].steamid, oldPoints, players[client].points);
	}
}

// Non-blocking callback for name history updates
void DBCT_NameHistoryUpdate(Handle db, Handle child, const char[] error, int userid) {
	if(db == null || child == null) {
		// Log the error but DON'T affect core functionality
		LogMessage("[l4d2_stats_recorder] Name history update failed (non-critical): %s", error);
	} else {
		// Success - name history updated for display purposes
		int client = GetClientOfUserId(userid);
		if(client > 0) {
			PrintToServer("[l4d2_stats_recorder] Name history updated successfully for %N", client);
		}
	}
}

// Callback to ensure user exists before submitting points
void DBCT_EnsureUserExists(Handle db, Handle child, const char[] error, int userid) {
	int client = GetClientOfUserId(userid);
	
	if(db == null || child == null) {
		LogError("[l4d2_stats_recorder] Failed to ensure user exists: %s", error);
		if(client > 0) {
			PrintToServer("[l4d2_stats_recorder] ERROR: Cannot create user for %N (%s) - points may be lost!", 
				client, players[client].steamid);
		}
		return;
	}
	
	// User now exists (either was created or already existed)
	if(client > 0 && IsClientInGame(client)) {
		PrintToServer("[l4d2_stats_recorder] User confirmed exists for %N (%s), submitting %d queued points", 
			client, players[client].steamid, players[client].pointsQueue.Length);
		SubmitPointsNow(client);
		
		// CRITICAL: Also update total points in stats_users table immediately
		// This ensures leaderboards show current points, not just game-end totals
		char updateQuery[256];
		Format(updateQuery, sizeof(updateQuery), 
			"UPDATE stats_users SET points=%d WHERE steamid='%s'",
			players[client].points, players[client].steamid);
		SQL_TQuery(g_db, DBCT_UpdateTotalPoints, updateQuery, GetClientUserId(client));
	}
}

// Callback for updating total points in stats_users
void DBCT_UpdateTotalPoints(Handle db, Handle child, const char[] error, int userid) {
	int client = GetClientOfUserId(userid);
	if(db == null || child == null) {
		LogError("[l4d2_stats_recorder] Failed to update total points: %s", error);
		if(client > 0) {
			PrintToServer("[l4d2_stats_recorder] ERROR: Could not update total points for %N (%s)", 
				client, players[client].steamid);
		}
	} else {
		if(client > 0 && IsClientInGame(client)) {
			PrintToServer("[l4d2_stats_recorder] Successfully updated total points for %N (%s): %d", 
				client, players[client].steamid, players[client].points);
		}
	}
}

// Emergency user creation callback
void DBCT_EmergencyUserCreation(Handle db, Handle child, const char[] error, int userid) {
	int client = GetClientOfUserId(userid);
	
	if(db == null || child == null) {
		LogError("[l4d2_stats_recorder] Emergency user creation failed: %s", error);
		if(client > 0) {
			PrintToServer("[l4d2_stats_recorder] CRITICAL: Emergency user creation failed for %N (%s)", 
				client, players[client].steamid);
		}
	} else {
		if(client > 0) {
			PrintToServer("[l4d2_stats_recorder] Emergency user created successfully for %N (%s)", 
				client, players[client].steamid);
		}
	}
}

void DBCT_Migration(Handle db, Handle child, const char[] error, int migrationIndex) {
	if(db == null || child == null) {
		LogError("Migration #%d failed: %s", migrationIndex, error);
	}
}
void DBCT_RateMap(Handle db, Handle child, const char[] error, int userid) { 
	int client = GetClientOfUserId(userid);
	if(client == 0) return;
	if(db == null || child == null) {
		LogError("DBCT_RateMap error: %s", error);
		PrintToChat(client, "An error occurred while rating campaign");
	} else {
		PrintToChat(client, "Rating submitted for %s", game.mapTitle);
	}
}
void SubmitMapInfo() {
	char title[128];
	InfoEditor_GetString(0, "DisplayTitle", title, sizeof(title));
	int chapters = L4D_GetMaxChapters();
	char query[128];
	g_db.Format(query, sizeof(query), "INSERT INTO map_info (mapid,name,chapter_count) VALUES ('%s','%s',%d)", game.mapId, title, chapters);
	g_db.Query(DBCT_Generic, query, QUERY_MAP_INFO, DBPrio_Low);
}
#define MAX_UUID_RETRY_ATTEMPTS 1
public void DBCT_GetUUIDForCampaign(Handle db, DBResultSet results, const char[] error, int attempt) {
	if(results != INVALID_HANDLE) {
		if(results.FetchRow()) {
			results.FetchString(0, game.uuid, sizeof(game.uuid));
			DBResult result;
			bool hasData = results.FetchInt(1, result) && result == DBVal_Data;
			// PrintToServer("mapinfo: %d. result: %d. hasData:%b", results.FetchInt(1), result, hasData);
			if(!hasData) {
				SubmitMapInfo();
			}
			PrintToServer("UUID for campaign: %s | Difficulty: %d", game.uuid, game.difficulty);
			return;
		} else {
			game.uuid[0] = '\0';
			LogError("RecordCampaign, failed to get UUID: no data was returned");
		}
	} else {
		LogError("RecordCampaign, failed to get UUID: %s", error);
	}
	// Error
	game.uuid[0] = '\0';
	if(attempt < MAX_UUID_RETRY_ATTEMPTS) {
		FetchUUID(attempt + 1);
	}
}
//After a user's stats were flushed, reset any statistics needed to zero.
public void DBCT_FlushQueuedStats(Handle db, Handle child, const char[] error, int userid) {
	if(db == INVALID_HANDLE || child == INVALID_HANDLE) {
		LogError("DBCT_FlushQueuedStats returned error: %s", error);
	}else{
		int client = GetClientOfUserId(userid);
		if(client > 0)
			ResetInternal(client, false);
	}
}
////////////////////////////
// COMMANDS
///////////////////////////

#define DATE_FORMAT "%F at %I:%M %p"
Action Command_PlayerStats(int client, int args) {
	if(args == 0) {
		ReplyToCommand(client, "Syntax: /stats <player name>");
		return Plugin_Handled;
	}
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[1], target_count;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			1,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	int player = target_list[0];
	if(player > 0) {
		ReplyToCommand(client, "");
		ReplyToCommand(client, "\x04Name: \x05%N", player);
		ReplyToCommand(client, "\x04Points: \x05%d", players[player].points);
		ReplyToCommand(client, "\x04Joins: \x05%d", players[player].connections);
		FormatTime(arg, sizeof(arg), DATE_FORMAT, players[player].firstJoinedTime);
		ReplyToCommand(client, "\x04First Joined: \x05%s", arg);
		FormatTime(arg, sizeof(arg), DATE_FORMAT, players[player].lastJoinedTime);
		ReplyToCommand(client, "\x04Last Joined: \x05%s", arg);
		if(players[player].idleStartTime > 0) {
			FormatTime(arg, sizeof(arg), DATE_FORMAT, players[player].idleStartTime);
			ReplyToCommand(client, "\x04Idle Start Time: \x05%s", arg);
		}
		ReplyToCommand(client, "\x04Minutes Idle: \x05%d", players[player].totalIdleTime);
	}

	return Plugin_Handled;
}

#if defined DEBUG
public Action Command_DebugStats(int client, int args) {
	if(client == 0 && !IsDedicatedServer()) {
		ReplyToCommand(client, "This command must be used as a player.");
	}else {
		ReplyToCommand(client, "Statistics for %s", players[client].steamid);
		ReplyToCommand(client, "lastDamage = %f", players[client].lastWeaponDamage);
		ReplyToCommand(client, "points = %d", players[client].points);
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2) {
				ReplyToCommand(client, "p#%i | pending heatmaps: %d | ", i, players[i].pendingHeatmaps.Length, players[i].pointsQueue.Length);
			}
		}
		ReplyToCommand(client, "connections = %d", players[client].connections);
		// ReplyToCommand(client, "Total weapons cache %d", game.weaponUsages.Size);
	}
	return Plugin_Handled;
}
#endif

// RATING

Menu SetupRateMenu() {
	Menu menu = new Menu(MapVoteHandler);
	menu.SetTitle("Rate Map");
	menu.AddItem("1", "1 stars (Bad)");
	menu.AddItem("2", "2 stars");
	menu.AddItem("3", "3 stars");
	menu.AddItem("4", "4 stars");
	menu.AddItem("5", "5 stars (Good)");
	menu.ExitButton = true;
	return menu;
}

Action Command_RateMap(int client, int args) {
	if(!L4D_IsMissionFinalMap()) {
		ReplyToCommand(client, "Can only rate on map finales");
		return Plugin_Handled;
	}
	if(args == 0) {
		g_rateMenu.SetTitle("Rate %s", game.mapTitle);
		g_rateMenu.Display(client, 0);
	} else {
		char arg[255];
		GetCmdArg(1, arg, sizeof(arg));
		int value = StringToInt(arg);
		if(value <= 0 || value > 5) {
			ReplyToCommand(client, "Invalid rating, must be between 1 (low) and 5 (high). Syntax: /rate <1-5>");
			return Plugin_Handled;
		} 
		if(args > 1) {
			if(GetUserAdmin(client) == INVALID_ADMIN_ID) {
				ReplyToCommand(client, "Only server admins can add comments with their rating. Syntax: /rate <1-5>");
				return Plugin_Handled;
			}
			GetCmdArg(2, arg, sizeof(arg));
		}

		SubmitMapRating(client, value, arg);
	}
	return Plugin_Handled;
}

void SubmitMapRating(int client, int rating, const char[] comment = "") {
	char query[1024];
	g_db.Format(query, sizeof(query), "INSERT INTO map_ratings (map_id,steamid,value,comment) VALUES ('%s','%s',%d,'%s') ON DUPLICATE KEY UPDATE value = %d, comment = '%s'",
		game.mapId,
		players[client].steamid,
		rating,
		comment,
		rating,
		comment
	);
	g_db.Query(DBCT_RateMap, query, GetClientUserId(client));
}

int MapVoteHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		static char info[2];
		menu.GetItem(param2, info, sizeof(info));
		int value = StringToInt(info);
		if(players[param1].steamid[0] == '\0') return 0;
		
		SubmitMapRating(param1, value);
	} else if (action == MenuAction_End) {
		// Don't delete, shared menu
	} 
	return 0;
}

////////////////////////////
// EVENTS 
////////////////////////////
void Event_PlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast) {
	if(GetSurvivorCount() > 4) return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		// Check if they do not have a kit
		if(GetPlayerWeaponSlot(client, 3) == -1) {
			// Check if there are any kits remaining in the safe area (that they did not pickup)
			int entity = -1;
			float pos[3];
			while((entity = FindEntityByClassname(entity, "weapon_first_aid_kit_spawn")) != INVALID_ENT_REFERENCE) {
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
				if(L4D_IsPositionInLastCheckpoint(pos)) {
					PrintToConsoleAll("[Stats] Player %N forgot to pickup a kit", client);
					IncrementStat(client, "forgot_kit_count");
					break;
				}
			}
		}
	}
}
void OnWeaponSwitch(int client, int weapon) {
	// Update weapon when switching to a new one
	if(weapon > -1) {
		
		// TODO: if melee
		players[client].wpn.SetActiveWeapon(weapon);
	}
}
public void Event_BoomerExploded(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2) {
		g_iLastBoomTime = GetGameTime();
		g_iLastBoomUser = attacker;
	}
}

public Action L4D_OnVomitedUpon(int victim, int &attacker, bool &boomerExplosion) {
	if(boomerExplosion && GetGameTime() - g_iLastBoomTime < 23.0) {
		if(victim == g_iLastBoomUser)
			IncrementStat(g_iLastBoomUser, "boomer_mellos_self");
		else
			IncrementStat(g_iLastBoomUser, "boomer_mellos");
	}
	return Plugin_Continue;
}

Action SoundHook(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed) {
	if(numClients > 0 && StrContains(sample, "clown") > -1) {
		// The sound of the honk comes from the honker directly, so we loop all the receiving clients
		// Then the one with the exact coordinates of the sound, is the honker 
		static float zPos[3], survivorPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", zPos);
		for(int i = 0; i < numClients; i++) {
			int client = clients[i];
			GetClientAbsOrigin(client, survivorPos);
			if(survivorPos[0] == zPos[0] && survivorPos[1] == zPos[1] && survivorPos[2] == zPos[2]) {
				game.clownHonks++;
				players[client].clownsHonked++;
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}
//Records the amount of HP done to infected (zombies)
public void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker > 0 && !IsFakeClient(attacker)) {
		int dmg = event.GetInt("amount");
		players[attacker].damageSurvivorGiven += dmg;
		players[attacker].wpn.damage += dmg;
	}
}
public void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	PrintToServer("[l4d2_stats_recorder] InfectedDeath event: attacker=%d", attacker);
	
	if(attacker > 0 && !IsFakeClient(attacker)) {
		PrintToServer("[l4d2_stats_recorder] Valid attacker %N (ID:%d, Team:%d, SteamID:'%s')", 
			attacker, attacker, GetClientTeam(attacker), players[attacker].steamid);
			
		bool blast = event.GetBool("blast");
		bool headshot = event.GetBool("headshot");
		bool using_minigun = event.GetBool("minigun");

		if(headshot) {
			players[attacker].RecordPoint(PType_Headshot, 2);
			players[attacker].wpn.headshots++;
		}

		players[attacker].RecordPoint(PType_CommonKill, 1);
		players[attacker].wpn.kills++;

		if(using_minigun) {
			players[attacker].minigunKills++;
		} else if(blast) {
			players[attacker].pipeKills++;
		}
	} else {
		if(attacker <= 0) {
			PrintToServer("[l4d2_stats_recorder] InfectedDeath: Invalid attacker ID %d", attacker);
		} else if(IsFakeClient(attacker)) {
			PrintToServer("[l4d2_stats_recorder] InfectedDeath: Attacker %d is fake client (bot)", attacker);
		}
	}
}
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim_team = GetClientTeam(victim);
	int dmg = event.GetInt("dmg_health");
	if(dmg <= 0) return;
	if(attacker > 0 && !IsFakeClient(attacker)) {
		int attacker_team = GetClientTeam(attacker);
		players[attacker].wpn.damage += dmg;


		if(attacker_team == 2) {
			players[attacker].damageSurvivorGiven += dmg;
			char wpn_name[16];
			event.GetString("weapon", wpn_name, sizeof(wpn_name));

			if(victim_team == 3 && StrEqual(wpn_name, "inferno", true)) {
				players[attacker].molotovDamage += dmg;
			}
		} else if(attacker_team == 3) {
			players[attacker].damageInfectedGiven += dmg;
		}
		if(attacker_team == 2 && victim_team == 2) {
			// Flat friendly fire penalty: -40 per damage dealt to teammate
			int penalty = dmg * -40;
			
			players[attacker].RecordPoint(PType_FriendlyFire, penalty);
			players[attacker].damageSurvivorFF += dmg;
			players[attacker].damageSurvivorFFCount++;
			players[victim].damageFFTaken += dmg;
			players[victim].damageFFTakenCount++;
		}
	}
	
	// Tank damage tracking for multiple tanks support
	if(g_bTankInPlay && victim == g_iTankClient && attacker > 0 && IsClientInGame(attacker) && !IsFakeClient(attacker)) {
		// Track damage to current tank only
		g_iTankDamage[attacker] += dmg;
		
		#if defined DEBUG
		PrintToServer("[DEBUG] Tank damage: attacker=%d, damage=%d, total=%d", attacker, dmg, g_iTankDamage[attacker]);
		#endif
	}
}
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(victim > 0) {
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		int victim_team = GetClientTeam(victim);

		if(!IsFakeClient(victim)) {
			if(victim_team == 2) {
				IncrementBothStats(victim, "survivor_deaths", 1);
				float pos[3];
				GetClientAbsOrigin(victim, pos);
				players[victim].RecordHeatMap(HeatMap_Death, pos);
			}
		}

		if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2) {
			if(victim_team == 3) {
				int victim_class = GetEntProp(victim, Prop_Send, "m_zombieClass");
				char class[8], statname[16];
				players[attacker].wpn.kills++;


				if(GetInfectedClassName(victim_class, class, sizeof(class))) {
					IncrementSpecialKill(attacker, victim_class);
					Format(statname, sizeof(statname), "kills_%s", class);
					IncrementBothStats(attacker, statname, 1);
					players[attacker].RecordPoint(PType_SpecialKill, 6);
				}
				char wpn_name[16];
				event.GetString("weapon", wpn_name, sizeof(wpn_name));
				if(StrEqual(wpn_name, "inferno", true) || StrEqual(wpn_name, "entityflame", true)) {
					players[attacker].molotovKills++;
				}
				IncrementBothStats(victim, "infected_deaths", 1);
			} else if(victim_team == 2) {
				IncrementBothStats(attacker, "ff_kills", 1);
				//30 point lost for killing teammate
				players[attacker].RecordPoint(PType_FriendlyFire, -500);
			}
		}
	}
	
}
public void Event_MeleeKill(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		players[client].RecordPoint(PType_CommonKill, 1);
	}
}
public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client)) {
		// Clear previous tank damage tracking
		ClearTankDamage();
		
		// Set tank tracking variables
		g_bTankInPlay = true;
		g_iTankClient = client;
		g_iTankHealth = GetClientHealth(client);
		
		#if defined DEBUG
		PrintToServer("[DEBUG] Tank spawned: client=%d, health=%d", client, g_iTankHealth);
		#endif
	}
}


public void Event_TankKilled(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int solo = event.GetBool("solo") ? 1 : 0;
	int melee_only = event.GetBool("melee_only") ? 1 : 0;

	// Calculate total damage dealt to this specific tank
	int totalTankDamage = 0;
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i)) {
			totalTankDamage += g_iTankDamage[i];
		}
	}
	
	// Distribute 100 points total based on damage contribution to this tank
	if(totalTankDamage > 0) {
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i) && g_iTankDamage[i] > 0) {
				// Calculate damage percentage and award points proportionally
				float damagePercent = float(g_iTankDamage[i]) / float(totalTankDamage);
				int points = RoundToNearest(damagePercent * 100.0);
				
				if(points > 0) {
					players[i].RecordPoint(PType_TankKill, points);
					IncrementBothStats(i, "tanks_killed", 1);
					
					#if defined DEBUG
					PrintToServer("[DEBUG] Tank kill points: player=%d, damage=%d/%d (%.1f%%), points=%d", i, g_iTankDamage[i], totalTankDamage, damagePercent * 100.0, points);
					#endif
				}
			}
		}
	}
	
	// Award bonus points only to the attacker (killer)
	if(attacker > 0 && !IsFakeClient(attacker)) {
		if(solo) {
			IncrementStat(attacker, "tanks_killed_solo", 1);
			players[attacker].RecordPoint(PType_TankKill_Solo, 20);
		}
		if(melee_only) {
			players[attacker].RecordPoint(PType_TankKill_Melee, 50);
			IncrementStat(attacker, "tanks_killed_melee", 1);
		}
	}
	
	// Reset tank tracking
	g_bTankInPlay = false;
	g_iTankClient = 0;
	g_iTankHealth = 0;
}
public void Event_DoorOpened(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && event.GetBool("closed") && !IsFakeClient(client)) {
		players[client].doorOpens++;

	}
}
void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client) && GetClientTeam(client) == 2) {
		IncrementBothStats(client, "survivor_incaps", 1);
		float pos[3];
		GetClientAbsOrigin(client, pos);
		players[client].RecordHeatMap(HeatMap_Incap, pos);
	}
}
void Event_LedgeGrab(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client) && GetClientTeam(client) == 2) {
		float pos[3];
		GetClientAbsOrigin(client, pos);
		players[client].RecordHeatMap(HeatMap_LedgeGrab, pos);
		IncrementBothStats(client, "survivor_incaps", 1);
	}
}
//Track heals, or defibs
void Event_ItemUsed(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		if(StrEqual(name, "heal_success", true)) {
			int subject = GetClientOfUserId(event.GetInt("subject"));
			if(subject == client) {
				IncrementStat(client, "heal_self", 1);
			}else{
				// Anti-abuse: Check heal cooldown and target health
				int targetHealth = GetClientHealth(subject);
				int targetMaxHealth = GetEntProp(subject, Prop_Send, "m_iMaxHealth");
				int healthPercent = RoundToNearest((float(targetHealth) / float(targetMaxHealth)) * 100.0);
				
				if(healthPercent <= HEAL_HEALTH_THRESHOLD) {
					if(IsHealCooldownExpired(client, subject)) {
						// Award points based on target health
						int healPoints = (healthPercent <= HEAL_CRITICAL_THRESHOLD) ? 60 : 40;
						players[client].RecordPoint(PType_HealOther, healPoints);
						SetHealTime(client, subject);
						
						PrintToServer("[AntiAbuse] %N earned %d heal points on %N (%d%% health)", 
							client, healPoints, subject, healthPercent);
					} else {
						int timeLeft = GetHealCooldownRemaining(client, subject);
						PrintToChat(client, "[Heal Cooldown] Wait %d seconds before earning points for healing %N again", 
							timeLeft, subject);
					}
				} else {
					PrintToChat(client, "[Heal] No points awarded - %N has sufficient health (%d%%)", 
						subject, healthPercent);
				}
				IncrementBothStats(client, "heal_others", 1);
			}
		} else if(StrEqual(name, "revive_success", true)) {
			int subject = GetClientOfUserId(event.GetInt("subject"));
			if(subject != client) {
				IncrementBothStats(client, "revived_others", 1);
				players[client].RecordPoint(PType_ReviveOther, 25);
				IncrementBothStats(subject, "revived", 1);
			}
		} else if(StrEqual(name, "defibrillator_used", true)) {
			players[client].RecordPoint(PType_ResurrectOther, 50);
			IncrementBothStats(client, "defibs_used", 1);
		} else{
			IncrementStat(client, name, 1);
		}
	}
}

public void Event_UpgradePackUsed(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		players[client].upgradePacksDeployed++;
		players[client].RecordPoint(PType_DeployAmmo, 20);
	}
}
public void Event_CarAlarm(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		IncrementStat(client, "caralarms_activated", 1);
	}
}
public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		players[client].witchKills++;
		players[client].RecordPoint(PType_WitchKill, 15);
	}
}

// Tank damage tracking helper functions
void ClearTankDamage() {
	for(int i = 1; i <= MaxClients; i++) {
		g_iTankDamage[i] = 0;
	}
}

// Anti-abuse: Heal cooldown helper functions
bool IsHealCooldownExpired(int healer, int target) {
	int currentTime = GetTime();
	int lastHealTime = g_iLastHealTime[healer][target];
	return (currentTime - lastHealTime) >= HEAL_COOLDOWN_TIME;
}

void SetHealTime(int healer, int target) {
	g_iLastHealTime[healer][target] = GetTime();
}

int GetHealCooldownRemaining(int healer, int target) {
	int currentTime = GetTime();
	int lastHealTime = g_iLastHealTime[healer][target];
	int timeElapsed = currentTime - lastHealTime;
	return (timeElapsed >= HEAL_COOLDOWN_TIME) ? 0 : (HEAL_COOLDOWN_TIME - timeElapsed);
}

void ResetHealCooldowns() {
	for(int i = 1; i <= MaxClients; i++) {
		for(int j = 1; j <= MaxClients; j++) {
			g_iLastHealTime[i][j] = 0;
		}
	}
	PrintToServer("[AntiAbuse] Heal cooldowns reset (plugin reload)");
}

int FindTankClient() {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && GetClientTeam(i) == 3) {
			if(GetEntProp(i, Prop_Send, "m_zombieClass") == ZOMBIECLASS_TANK) {
				return i;
			}
		}
	}
	return 0;
}


public void Event_GrenadeDenonate(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		char wpn_name[32];
		GetClientWeapon(client, wpn_name, sizeof(wpn_name));
	}
}
///THROWABLE TRACKING
//This is used to track throwable throws 
public void OnEntityCreated(int entity, const char[] classname) {
	if(IsValidEntity(entity) && StrContains(classname, "_projectile", true) > -1 && HasEntProp(entity, Prop_Send, "m_hOwnerEntity")) {
		RequestFrame(EntityCreateCallback, entity);
	}
}
void EntityCreateCallback(int entity) {
	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity") || !IsValidEntity(entity)) return;
	char class[16];

	GetEntityClassname(entity, class, sizeof(class));
	int entOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(entOwner > 0 && entOwner <= MaxClients) {
		if(StrContains(class, "vomitjar", true) > -1) {
			IncrementStat(entOwner, "throws_puke", 1);
		} else if(StrContains(class, "molotov", true) > -1) {
			IncrementStat(entOwner, "throws_molotov", 1);
		} else if(StrContains(class, "pipe_bomb", true) > -1) {
			IncrementStat(entOwner, "throws_pipe", 1);
		}
	}
}
public void L4D2_CInsectSwarm_CanHarm_Post(int acid, int spitter, int entity) {
	if(entity <= 32 && GetClientTeam(entity) == 2) {
		players[entity].timeInAcid.TryStart();
	}
	// TODO: accumulate
}
public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {
	if(GetEntityFlags(client) & FL_ONFIRE) {
		players[client].timeInFire.TryStart();
	} else {
		players[client].timeInFire.TryEnd();
	}
}
bool isTransition = false;
////MAP EVENTS
public void Event_GameStart(Event event, const char[] name, bool dontBroadcast) {
	game.startTime = GetTime();
	game.clownHonks = 0;
	game.submitted = false;

	PrintToServer("[l4d2_stats_recorder] Started recording statistics for new session");
	for(int i = 1; i <= MaxClients; i++) {
		ResetSessionStats(i, true);
		ResetInternal(i, true);
	}
}
public void OnMapStart() {
	if(isTransition) {
		isTransition = false;
	}else{
		game.difficulty = GetDifficultyInt();
	}
	game.GetMap();
	
	// Reset map session start time for all connected players
	int currentTime = GetTime();
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && players[i].steamid[0]) {
			players[i].mapSessionStart = currentTime;
		}
	}
}
public void OnMapEnd() {
	if(g_HeatMapEntities != null) delete g_HeatMapEntities;
}
public void Event_VersusRoundStart(Event event, const char[] name, bool dontBroadcast) {
	if(game.IsVersusMode()) {
		game.isVersusSwitched = !game.isVersusSwitched; 
	}
}
public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast) {
	isTransition = true;
	for(int i = 1; i <= MaxClients; i++) {
		// CRITICAL FIX: Process ALL survivor team players, dead or alive
		// Dead players also need their points submitted during map transitions!
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i)) {
			bool isAlive = IsPlayerAlive(i);
			PrintToServer("[l4d2_stats_recorder] Map transition - flushing stats for %N (alive: %s)", i, isAlive ? "yes" : "no");
			IncrementSessionStat(i);
			FlushQueuedStats(i, false);
		}
	}
}
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	PrintToServer("[l4d2_stats_recorder] round_end; flushing");
	game.finished = false;
	
	for(int i = 1; i <= MaxClients; i++) {
		// CRITICAL FIX: Process ALL survivor team players, dead or alive
		// Dead players also need their points submitted!
		if(IsClientInGame(i) && GetClientTeam(i) == 2) {
			bool isAlive = IsPlayerAlive(i);
			PrintToServer("[l4d2_stats_recorder] Flushing stats for %N (alive: %s)", i, isAlive ? "yes" : "no");
			//ResetSessionStats(i, false);
			FlushQueuedStats(i, false);
		}
	}
}
/*Order of events:
finale_start: Gets UUID
escape_vehicle_ready: IF fired, sets var campaignFinished to true.
finale_win: Record all players, campaignFinished = false

if player disconnects && campaignFinished: record their session. Won't be recorded in finale_win
*/
//Fetch UUID from finale start, should be ready for events finale_win OR escape_vehicle_ready
void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast) {
	game.finaleStartTime = GetTime();
	game.difficulty = GetDifficultyInt();
	//Use the same UUID for versus
	//FIXME: This was causing UUID to not fire another new one for back-to-back-coop
	//if(game.IsVersusMode && game.isVersusSwitched) return;
	FetchUUID();
}
void FetchUUID(int attempt = 0) {
	char query[128];
	g_db.Format(query, sizeof(query), "SELECT UUID() AS UUID, (SELECT !ISNULL(mapid) from map_info where mapid = '%s') as mapid", game.mapId);
	g_db.Query(DBCT_GetUUIDForCampaign, query, attempt);
}
void Event_FinaleVehicleReady(Event event, const char[] name, bool dontBroadcast) {
	//Get UUID on finale_start
	if(L4D_IsMissionFinalMap()) {
		game.difficulty = GetDifficultyInt();
		game.finished = true;
	}
}

void Event_FinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast) {
	// if(L4D_IsMissionFinalMap()) {
	// 	// TODO: check if user has rated?
	// 	g_rateMenu.SetTitle("Rate %s", game.mapTitle);
	// 	for(int i = 1; i <= MaxClients; i++) {
	// 		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2) {
	// 			// g_rateMenu.Display(i, 0);
	// 		}
	// 	}
	// }
}

void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast) {
	if(!L4D_IsMissionFinalMap() || game.submitted) return;
	game.difficulty = event.GetInt("difficulty");
	game.finished = false;
	char shortID[9];
	StrCat(shortID, sizeof(shortID), game.uuid);

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && GetClientTeam(i) == 2) {
			int client = i;
			if(IsFakeClient(i)) {
				if(!HasEntProp(i, Prop_Send, "m_humanSpectatorUserID")) continue;
				client = GetClientOfUserId(GetEntPropEnt(i, Prop_Send, "m_humanSpectatorUserID"));
				//get real client
			}
			if(players[client].steamid[0]) {
				players[client].RecordPoint(PType_FinishCampaign, 1000);
				IncrementSessionStat(client);
				RecordCampaign(client);
				IncrementBothStats(client, "finales_won", 1);
				if(game.uuid[0] != '\0')
					// PrintToChat(client, "View this game's statistics at <your-domain>/c/%s", shortID);
				if(game.clownHonks > 0) {
					PrintToChat(client, "%d clowns were honked this session, you honked %d", game.clownHonks, players[client].clownsHonked);
				}
			}

		}
	}	
	if(game.clownHonks > 0) {
		ArrayList winners = new ArrayList();
		int mostHonks;
		for(int j = 1; j <= MaxClients; j++) {
			if(players[j].clownsHonked <= 0 || !IsClientInGame(j) || IsFakeClient(j)) continue;
			if(players[j].clownsHonked > mostHonks || winners.Length == 0) {
				mostHonks = players[j].clownsHonked;
				// Clear the winners list
				winners.Clear();
				winners.Push(j);
			} else if(players[j].clownsHonked == mostHonks) {
				// They are tied with the current winner, add them to list
				winners.Push(j);
			}
		}

		if(mostHonks > 0) {
			if(winners.Length > 1) {
				char msg[256];
				Format(msg, sizeof(msg), "%N", winners.Get(0));
				for(int i = 1; i < winners.Length; i++) {
					int winner = winners.Get(i);
					if(!IsClientConnected(winner)) continue;
					if(i == winners.Length - 1) {
						// If this is the last winner, use 'and '
						Format(msg, sizeof(msg), "%s and %N", msg, winner);
					} else {
						// In between first and last winner, comma
						Format(msg, sizeof(msg), "%s, %N", msg, winner);
					}
				}
				PrintToChatAll("%s tied for the most clown honks with a count of %d", msg, mostHonks);
			} else {
				int winner = winners.Get(0);
				if(IsClientConnected(winner)) {
					PrintToChatAll("%N had the most clown honks with a count of %d", winner, mostHonks);
				}
			}
		} 
		delete winners;
	}
	for(int i = 1; i <= MaxClients; i++) {
		players[i].clownsHonked = 0;
		if(IsClientInGame(i) && !IsFakeClient(i)) {
			PrintToChat(i, "Rate this map with /rate # (1 lowest, 5 highest)");
		}
	}
	game.submitted = true;
	game.clownHonks = 0;
}


////////////////////////////
// FORWARD EVENTS
///////////////////////////
public void OnWitchCrown(int survivor, int damage) {
	IncrementStat(survivor, "witches_crowned", 1);
}
public void OnSmokerSelfClear( int survivor, int smoker, bool withShove ) {
	IncrementStat(survivor, "smokers_selfcleared", 1);
}
public void OnTankRockEaten( int tank, int survivor ) {
	IncrementStat(survivor, "rocks_hitby", 1);
}
public void OnHunterDeadstop(int survivor, int hunter) {
	IncrementStat(survivor, "hunters_deadstopped", 1);
}
public void OnSpecialClear( int clearer, int pinner, int pinvictim, int zombieClass, float timeA, float timeB, bool withShove ) {
	IncrementStat(clearer, "cleared_pinned", 1);
	IncrementStat(pinvictim, "times_pinned", 1);
	
	// Award points for saving teammate from special infected
	if(clearer > 0 && !IsFakeClient(clearer)) {
		players[clearer].RecordPoint(PType_Generic, 20);
	}
}
////////////////////////////
// NATIVES
///////////////////////////
public any Native_GetPoints(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	return players[client].points;
}

// Debug command to check player point status - STEAM ID FOCUSED
public Action Command_CheckPlayerPoints(int client, int args) {
	PrintToServer("[l4d2_stats_recorder] === Steam ID-Centric Point Recording Debug ===");
	
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i)) {
			bool steamid_valid = (strlen(players[i].steamid) >= 8 && StrContains(players[i].steamid, "STEAM_") == 0);
			char name_buffer[MAX_NAME_LENGTH];
			GetClientName(i, name_buffer, sizeof(name_buffer));
			
			PrintToServer("[l4d2_stats_recorder] Player %N (ID:%d):", i, i);
			PrintToServer("  - ✅ SteamID: '%s' (Valid: %s)", players[i].steamid, steamid_valid ? "YES" : "NO");
			PrintToServer("  - 📊 Points: %d (Queue: %d)", players[i].points, players[i].pointsQueue.Length);
			PrintToServer("  - 👥 Team: %d", GetClientTeam(i));
			PrintToServer("  - 🎮 Name: '%s' (Length: %d)", name_buffer, strlen(name_buffer));
			PrintToServer("  - ⏱️ Minutes played: %d", (GetTime() - players[i].startedPlaying) / 60);
			PrintToServer("  - 🔄 Ready for point recording: %s", steamid_valid ? "YES" : "NO");
			PrintToServer("");
		}
	}
	
	PrintToServer("[l4d2_stats_recorder] === End Steam ID Debug ===");
	return Plugin_Handled;
}

////////////////////////////
// STOCKS
///////////////////////////
//Simply prints the respected infected's class name based on their numeric id. (not client/user ID)
stock bool GetInfectedClassName(int type, char[] buffer, int bufferSize) {
	switch(type) {
		case 1: strcopy(buffer, bufferSize, "smoker");
		case 2: strcopy(buffer, bufferSize, "boomer");
		case 3: strcopy(buffer, bufferSize, "hunter");
		case 4: strcopy(buffer, bufferSize, "spitter");
		case 5: strcopy(buffer, bufferSize, "jockey");
		case 6: strcopy(buffer, bufferSize, "charger");
		default: return false;
	}
	return true;
}

stock int GetDifficultyInt() {
	char diff[16];
	hZDifficulty.GetString(diff, sizeof(diff));
	if(StrEqual(diff, "easy", false)) return 0;
	else if(StrEqual(diff, "hard", false)) return 2;
	else if(StrEqual(diff, "impossible", false)) return 3;
	else return 1;
}

stock int GetSurvivorCount() {
	int count;
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && GetClientTeam(i) == 2) {
			count++;
		}
	}
	return count;
}