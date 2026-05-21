const ApiError = require('../utils/apiError');

async function updateCardState({
  connection,
  actionType,
  cardIds,
}) {
  if (!['BORROW', 'RETURN'].includes(actionType)) {
    throw new ApiError(400, 'Invalid actionType');
  }

  if (!Array.isArray(cardIds) || cardIds.length === 0) {
    throw new ApiError(400, 'cardIds is required');
  }

  const nextState = actionType === 'BORROW' ? 'InUse' : 'Normal';
  const currentState = actionType === 'BORROW' ? 'Normal' : 'InUse';

  const [result] = await connection.query(
    `
    UPDATE PASSCARD
    SET card_state = ?
    WHERE card_id IN (?)
      AND card_status = 'Active'
      AND card_state = ?
    `,
    [nextState, cardIds, currentState]
  );

  // BORROW = ต้อง update ครบทุกใบ
  if (actionType === 'BORROW' && result.affectedRows !== cardIds.length) {
    throw new ApiError(
      409,
      'Some cards cannot be borrowed (invalid state)'
    );
  }

  // RETURN = ถ้าไม่ update เลย ค่อย error
  if (actionType === 'RETURN' && result.affectedRows === 0) {
    // เช็คว่ามันถูกคืนไปแล้วหรือยัง
    const [rows] = await connection.query(
      `SELECT card_state FROM PASSCARD WHERE card_id IN (?)`,
      [cardIds]
    );
    if (!rows || rows.length === 0) {
      throw new ApiError(404, 'Card not found');
    }
    const alreadyReturned = rows.every(r => r.card_state === 'Normal');
    if (alreadyReturned) {
      return;
    }
    throw new ApiError(409, 'Invalid card state for return');
  }
}

module.exports = {
  updateCardState,
};