// relative path
require('./bar/../foo.js');
// absolute path
require('/bar/foo.js');
// mundle
require('foo');
// mundle with version
require('foo@1.1.1');
// mundle with relative
require('foo/bar.js');
// mundle with version and relative
require('foo@1.1.1/bar.js');