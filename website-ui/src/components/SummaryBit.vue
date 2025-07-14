<template>
<div>
    <nav v-if="hasSpecialInfectedKills" class="level">
        <div v-if="hasValue(values.boomer_kills)" class="level-item has-text-centered">
            <div>
            <p class="heading">Boomers Killed</p>
            <p class="title"><ICountUp :endVal="values.boomer_kills" /></p>
            </div>
        </div>
        <div v-if="hasValue(values.jockey_kills)" class="level-item has-text-centered">
            <div>
            <p class="heading">Jockeys Killed</p>
            <p class="title"><ICountUp :endVal="values.jockey_kills" /></p>
            </div>
        </div>
        <div v-if="hasValue(values.smoker_kills)" class="level-item has-text-centered">
            <div>
            <p class="heading">Smokers Killed</p>
            <p class="title"><ICountUp :endVal="values.smoker_kills" /></p>
            </div>
        </div>
        <div v-if="hasValue(values.spitter_kills)" class="level-item has-text-centered">
            <div>
            <p class="heading">Spitters Killed</p>
            <p class="title"><ICountUp :endVal="values.spitter_kills" /></p>
            </div>
        </div>
        <div v-if="hasValue(values.hunter_kills)" class="level-item has-text-centered">
            <div>
            <p class="heading">Hunters Killed</p>
            <p class="title"><ICountUp :endVal="values.hunter_kills" /></p>
            </div>
        </div>
        <div v-if="hasValue(values.charger_kills)" class="level-item has-text-centered">
            <div>
            <p class="heading">Chargers Killed</p>
            <p class="title"><ICountUp :endVal="values.charger_kills" /></p>
            </div>
        </div>
    </nav>
    <nav v-if="hasMedicalSupplies" class="level">
        <div v-if="hasValue(values.PillsUsed)" class="level-item has-text-centered">
            <div>
            <p class="heading">Pills Used</p>
            <p class="title"><ICountUp :endVal="values.PillsUsed" /></p>
            </div>
        </div>
        <div v-if="hasValue(values.AdrenalinesUsed)" class="level-item has-text-centered">
            <div>
            <p class="heading">Adrenalines Used</p>
            <p class="title"><ICountUp :endVal="values.AdrenalinesUsed" /></p>
            </div>
        </div>
        <div v-if="hasValue(selfMedkitsUsed)" class="level-item has-text-centered">
            <div>
            <p class="heading">Kits Used (Self)</p>
            <p class="title"><ICountUp :endVal="selfMedkitsUsed" /></p>
            </div>
        </div>
        <div v-if="hasValue(values.FirstAidShared)" class="level-item has-text-centered">
            <div>
            <p class="heading">Kits Used (Shared)</p>
            <p class="title"><ICountUp :endVal="values.FirstAidShared" /></p>
            </div>
        </div>
    </nav>
    <nav v-if="hasIncapsDeathsRevives" class="level">
        <div v-if="hasValue(values.Incaps)" class="level-item has-text-centered">
            <div>
            <p class="heading">Incaps</p>
            <p class="title"><ICountUp :endVal="values.Incaps" /></p>
            </div>
        </div>
        <div v-if="hasValue(values.Deaths)" class="level-item has-text-centered">
            <div>
            <p class="heading">Deaths</p>
            <p class="title"><ICountUp :endVal="values.Deaths" /></p>
            </div>
        </div>
        <div v-if="hasValue(values.ReviveOtherCount)" class="level-item has-text-centered">
            <div>
            <p class="heading">Revives (Others)</p>
            <p class="title"><ICountUp :endVal="values.ReviveOtherCount" /></p>
            </div>
        </div>
    </nav>
</div>
</template>

<script>
import ICountUp from 'vue-countup-v2';
export default {
    props: ['values', 'type'],
    components: {
        ICountUp
    },
    computed: {
        hasSpecialInfectedKills() {
            return this.hasValue(this.values.boomer_kills) ||
                   this.hasValue(this.values.jockey_kills) ||
                   this.hasValue(this.values.smoker_kills) ||
                   this.hasValue(this.values.spitter_kills) ||
                   this.hasValue(this.values.hunter_kills) ||
                   this.hasValue(this.values.charger_kills);
        },
        hasMedicalSupplies() {
            return this.hasValue(this.values.PillsUsed) ||
                   this.hasValue(this.values.AdrenalinesUsed) ||
                   this.hasValue(this.selfMedkitsUsed) ||
                   this.hasValue(this.values.FirstAidShared);
        },
        hasIncapsDeathsRevives() {
            return this.hasValue(this.values.Incaps) ||
                   this.hasValue(this.values.Deaths) ||
                   this.hasValue(this.values.ReviveOtherCount);
        },
        selfMedkitsUsed() {
            if (!this.values.MedkitsUsed || !this.values.FirstAidShared) return 0;
            return this.values.MedkitsUsed - this.values.FirstAidShared;
        }
    },
    methods: {
        hasValue(value) {
            return value !== null && value !== undefined && value > 0;
        },
        formatNumber(number) {
            if(!number) return 0;
            return Math.round(number).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        },
    }
}
</script>
