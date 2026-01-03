/**
 * Data helper utilities for API responses
 */

/**
 * Add calculated kills_all_specials field to user data
 * @param {Object|Array} data - Single user object or array of user objects
 * @returns {Object|Array} - Data with kills_all_specials field added
 */
export function addKillsAllSpecials(data) {
    if (!data) return data;

    // Handle array of objects
    if (Array.isArray(data)) {
        return data.map(item => addKillsAllSpecialsToSingle(item));
    }

    // Handle single object
    return addKillsAllSpecialsToSingle(data);
}

/**
 * Add calculated kills_all_specials field to a single user object
 * @param {Object} userData - Single user object
 * @returns {Object} - User data with kills_all_specials field added
 */
function addKillsAllSpecialsToSingle(userData) {
    if (!userData || typeof userData !== 'object') {
        return userData;
    }

    // Calculate kills_all_specials from individual special kill fields
    const killsAllSpecials = (
        (userData.kills_smoker || 0) +
        (userData.kills_boomer || 0) +
        (userData.kills_hunter || 0) +
        (userData.kills_spitter || 0) +
        (userData.kills_jockey || 0) +
        (userData.kills_charger || 0)
    );

    // Return new object with kills_all_specials added
    return {
        ...userData,
        kills_all_specials: killsAllSpecials
    };
}

/**
 * Add calculated special_infected_kills field (alias for kills_all_specials)
 * Used for consistency with different API response formats
 * @param {Object|Array} data - Single user object or array of user objects
 * @returns {Object|Array} - Data with special_infected_kills field added
 */
export function addSpecialInfectedKills(data) {
    if (!data) return data;

    // Handle array of objects
    if (Array.isArray(data)) {
        return data.map(item => addSpecialInfectedKillsToSingle(item));
    }

    // Handle single object
    return addSpecialInfectedKillsToSingle(data);
}

/**
 * Add calculated special_infected_kills field to a single user object
 * @param {Object} userData - Single user object
 * @returns {Object} - User data with special_infected_kills field added
 */
function addSpecialInfectedKillsToSingle(userData) {
    if (!userData || typeof userData !== 'object') {
        return userData;
    }

    // Calculate special_infected_kills from individual special kill fields
    const specialInfectedKills = (
        (userData.kills_smoker || 0) +
        (userData.kills_boomer || 0) +
        (userData.kills_hunter || 0) +
        (userData.kills_spitter || 0) +
        (userData.kills_jockey || 0) +
        (userData.kills_charger || 0)
    );

    // Return new object with special_infected_kills added
    return {
        ...userData,
        special_infected_kills: specialInfectedKills
    };
}
