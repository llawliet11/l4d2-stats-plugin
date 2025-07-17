import express from 'express';
import DataValidator from '../services/DataValidator.js';

const router = express.Router();
const validator = new DataValidator();

/**
 * @route GET /api/validation/health
 * @desc Get comprehensive data health report
 * @access Public (LOCAL DEV)
 */
router.get('/health', async (req, res) => {
    try {
        const healthReport = await validator.generateHealthReport();
        
        res.json({
            success: true,
            data: healthReport
        });
    } catch (error) {
        console.error('Error generating health report:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to generate health report',
            details: error.message
        });
    }
});

/**
 * @route GET /api/validation/user/:steamid
 * @desc Validate data consistency for a specific user
 * @access Public (LOCAL DEV)
 */
router.get('/user/:steamid', async (req, res) => {
    try {
        const { steamid } = req.params;
        
        if (!steamid) {
            return res.status(400).json({
                success: false,
                error: 'Steam ID is required'
            });
        }

        const validation = await validator.validateUserConsistency(steamid);
        
        res.json({
            success: true,
            data: validation
        });
    } catch (error) {
        console.error('Error validating user:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to validate user data',
            details: error.message
        });
    }
});

/**
 * @route GET /api/validation/batch
 * @desc Validate data consistency for multiple users
 * @access Public (LOCAL DEV)
 */
router.get('/batch', async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 100;
        
        if (limit > 1000) {
            return res.status(400).json({
                success: false,
                error: 'Limit cannot exceed 1000 users'
            });
        }

        const validation = await validator.validateAllUsersConsistency(limit);
        
        res.json({
            success: true,
            data: validation
        });
    } catch (error) {
        console.error('Error in batch validation:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to perform batch validation',
            details: error.message
        });
    }
});

/**
 * @route POST /api/validation/fix/:steamid
 * @desc Fix data inconsistencies for a specific user
 * @access Public (LOCAL DEV)
 */
router.post('/fix/:steamid', async (req, res) => {
    try {
        const { steamid } = req.params;
        
        if (!steamid) {
            return res.status(400).json({
                success: false,
                error: 'Steam ID is required'
            });
        }

        const fixResult = await validator.fixUserConsistency(steamid);
        
        if (fixResult.success) {
            res.json({
                success: true,
                message: 'User data consistency fixed successfully',
                data: fixResult
            });
        } else {
            res.status(500).json({
                success: false,
                error: 'Failed to fix user data consistency',
                details: fixResult.error
            });
        }
    } catch (error) {
        console.error('Error fixing user data:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fix user data consistency',
            details: error.message
        });
    }
});

/**
 * @route GET /api/validation/orphaned
 * @desc Check for orphaned records and invalid references
 * @access Public (LOCAL DEV)
 */
router.get('/orphaned', async (req, res) => {
    try {
        const orphanedData = await validator.checkOrphanedData();
        
        res.json({
            success: true,
            data: orphanedData
        });
    } catch (error) {
        console.error('Error checking orphaned data:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to check orphaned data',
            details: error.message
        });
    }
});

/**
 * @route GET /api/validation/stats/summary
 * @desc Get summary statistics about data validation
 * @access Public (LOCAL DEV)
 */
router.get('/stats/summary', async (req, res) => {
    try {
        // Get basic table counts and statistics
        const healthReport = await validator.generateHealthReport();
        
        const summary = {
            timestamp: new Date().toISOString(),
            table_counts: healthReport.table_counts,
            data_quality: {
                orphaned_sessions: healthReport.data_integrity.orphaned_data.total_orphaned_sessions || 0,
                invalid_map_references: healthReport.data_integrity.orphaned_data.total_invalid_map_sessions || 0,
                users_with_discrepancies: healthReport.data_integrity.sample_validation.users_with_discrepancies || 0
            },
            recommendations_count: healthReport.recommendations ? healthReport.recommendations.length : 0
        };
        
        res.json({
            success: true,
            data: summary
        });
    } catch (error) {
        console.error('Error getting validation summary:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get validation summary',
            details: error.message
        });
    }
});

/**
 * @route POST /api/validation/recalculate/all
 * @desc Recalculate all user statistics from map data (DANGEROUS OPERATION)
 * @access Public (LOCAL DEV)
 */
router.post('/recalculate/all', async (req, res) => {
    try {
        const { confirm } = req.body;
        
        if (confirm !== 'RECALCULATE_ALL_USERS') {
            return res.status(400).json({
                success: false,
                error: 'This operation requires confirmation. Send { "confirm": "RECALCULATE_ALL_USERS" } in request body.'
            });
        }

        // This is a potentially dangerous operation, so we'll limit it to a smaller batch
        const batchValidation = await validator.validateAllUsersConsistency(50);
        
        if (!batchValidation.validation_results || batchValidation.validation_results.length === 0) {
            return res.json({
                success: true,
                message: 'No users require recalculation',
                data: { users_processed: 0 }
            });
        }

        const results = {
            users_processed: 0,
            users_fixed: 0,
            errors: []
        };

        // Fix each user with discrepancies
        for (const userValidation of batchValidation.validation_results) {
            if (userValidation.steamid) {
                results.users_processed++;
                const fixResult = await validator.fixUserConsistency(userValidation.steamid);
                
                if (fixResult.success) {
                    results.users_fixed++;
                } else {
                    results.errors.push({
                        steamid: userValidation.steamid,
                        error: fixResult.error
                    });
                }
            }
        }
        
        res.json({
            success: true,
            message: `Recalculation completed. ${results.users_fixed}/${results.users_processed} users fixed.`,
            data: results
        });
    } catch (error) {
        console.error('Error in bulk recalculation:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to perform bulk recalculation',
            details: error.message
        });
    }
});

export default router;
