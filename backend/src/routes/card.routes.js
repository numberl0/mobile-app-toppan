// routes/card.routes.js
const express = require('express');
const authenticateToken = require('../middlewares/authenticateToken');
const router = express.Router();
const { db } = require("../config/db");
const ApiError = require('../utils/apiError');

// ---------------------------------------------- Get ---------------------------------------------- //
router.get(`/active-by-type`, authenticateToken, async (req, res, next) => {
  try {
    const { cardType } = req.query;
    let types = [];
    if (Array.isArray(cardType)) {
      types = cardType;
    } else if (typeof cardType === 'string') {
      types = cardType.split(',').map(t => t.trim());
    }

    const placeholders = types.map(() => '?').join(',');
    const query = `
      SELECT * FROM PASSCARD 
      WHERE card_type IN (${placeholders}) 
      AND card_status='Active' AND card_state = 'Normal'
    `;

    const [results] = await db.query(query, types);

    if (results.length === 0) {
      return next(new ApiError(404, 'Card not found'));
    }

    res.status(200).json({
      message: 'Get Card List Successfully',
      data: results
    });
  } catch (err) {
    next(err);
  }
});

router.get(`/cards-from-doc`, authenticateToken, async (req, res, next) => {
  try {
    const { cardIds } = req.query;
    let cards = [];
    if (Array.isArray(cardIds)) {
      cards = cardIds;
    } else if (typeof cardIds === 'string') {
      cards = cardIds.split(',').map(t => t.trim());
    }

    const placeholders = cards.map(() => '?').join(',');
    const query = `
      SELECT * FROM PASSCARD 
      WHERE card_id IN (${placeholders}) 
    `;

    const [results] = await db.query(query, cards);

    if (results.length === 0) {
      return next(new ApiError(404, 'Card not found'));
    }

    res.status(200).json({
      message: 'Get Card List Successfully',
      data: results
    });
  } catch (err) {
    next(err);
  }
});

router.post(`/card-action`, authenticateToken, async (req, res, next) => {
  try {
    const { action_type, list_card } = req.body;

    if (!['BORROW', 'RETURN'].includes(action_type)) {
      return next(new ApiError(400, 'Invalid action_type'));
    }

    if (!Array.isArray(list_card) || list_card.length === 0) {
      return next(new ApiError(400, 'list_card is required'));
    }

    const nextState = action_type === 'BORROW' ? 'InUse' : 'Normal';
    const currentState = action_type === 'BORROW' ? 'Normal' : 'InUse';

    for (const item of list_card) {
      const { card_id } = item;

      const [result] = await db.query(
        `
        UPDATE PASSCARD
        SET card_state = ?
        WHERE card_id = ?
          AND card_status = 'Active'
          AND card_state = ?
        `,
        [nextState, card_id, currentState]
      );

      if (result.affectedRows === 0) {
        return next(
          new ApiError(
            409,
            `Card ${card_id} cannot be ${action_type === 'BORROW' ? 'borrowed' : 'returned'}`
          )
        );
      }
    }

    res.status(200).json({
      message: `${action_type} card successfully`,
    });
  } catch (err) {
    next(err);
  }
});


module.exports = router;