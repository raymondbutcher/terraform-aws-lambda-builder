'use strict';

const jwt = require('jsonwebtoken');

exports.handler = function (event, context, callback) {
  const token = jwt.sign({ foo: 'bar' }, 'shhhhh');
  callback(null, { success: true, token: token });
};
