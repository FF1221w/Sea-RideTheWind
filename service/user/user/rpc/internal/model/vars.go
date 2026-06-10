package model

import "errors"

var (
	ErrorNotFound              = errors.New("record not found")
	ErrorAvatarHistoryNotFound = errors.New("avatar history not found")
)
