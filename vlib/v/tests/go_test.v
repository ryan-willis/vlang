import time

struct TestNumber {
mut:
	value int = 0
}

fn alter_value(x &TestNumber) {
	x.value = 42
}

fn test_go() {
	x := TestNumber{17}

	go alter_value(&x)

	time.sleep_ms(21)

	assert x.value == 42
}