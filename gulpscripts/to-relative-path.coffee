# �v���W�F�N�g���̐�΃p�X�𑊑΃p�X��

cwd = require('process').cwd().replace(/\\/g, '/')
re = new RegExp('^' + cwd + '/')

module.exports = (path) -> path.replace(/\\/g, '/').replace(re, '')

