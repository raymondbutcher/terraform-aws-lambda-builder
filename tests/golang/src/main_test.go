package main

import "testing"

func TestHandler(t *testing.T) {

	event := Event{Name: "gotest"}

	response, err := HandleRequest(event)

	if err != nil {
		t.Errorf("unexpected err, got: %v, wanted: %v", err, nil)
	}

	expected := "Hello gotest!"
	if response != expected {
		t.Errorf("unexpected response, got: %v, wanted %v", response, expected)
	}
}
