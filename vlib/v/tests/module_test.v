import os
import time as t
import crypto.sha256
import crypto { sha1, md5 }
import math
import log as l
import crypto.sha512

struct TestAliasInStruct {
	time t.Time
}

fn test_import() {
	info := l.Level.info
	hash := crypto.Hash.md4
	assert hash == .md4
	assert info == .info
	assert os.o_rdonly == os.o_rdonly
	assert t.month_days[0] == t.month_days[0]
	assert sha256.size == sha256.size
	assert math.pi == math.pi
	assert sha512.size == sha512.size
	assert md5.size == md5.size
	assert sha1.size == sha1.size
}

fn test_alias_in_struct_field() {
	a := TestAliasInStruct{
		time: t.Time{
			year: 2020
		}
	}
	assert a.time.year == 2020
}
