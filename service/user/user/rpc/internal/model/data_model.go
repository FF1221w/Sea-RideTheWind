package model

import "time"

type User struct {
	Id         uint64            `gorm:"primaryKey"`
	Uid        int64             `gorm:"column:uid;uniqueIndex;not null"`
	Username   string            `gorm:"column:username;unique"`
	Password   string            `gorm:"column:password"`
	Email      string            `gorm:"column:email;unique"`
	Status     int64             `gorm:"column:status;default:0"`
	Score      int32             `gorm:"column:score"`
	ExtraInfo  map[string]string `gorm:"column:extra_info;serializer:json"`
	CreateTime time.Time         `gorm:"column:create_time;autoCreateTime"`
	UpdateTime time.Time         `gorm:"column:update_time;autoUpdateTime"`
}

func (User) TableName() string {
	return "users"
}

type UserAvatarHistory struct {
	Id          uint64    `gorm:"primaryKey"`
	HistoryID   string    `gorm:"column:history_id;uniqueIndex;not null"`
	Uid         int64     `gorm:"column:uid;index;not null"`
	AvatarURL   string    `gorm:"column:avatar_url;not null"`
	ContentType string    `gorm:"column:content_type"`
	SizeBytes   int64     `gorm:"column:size_bytes"`
	IsCurrent   bool      `gorm:"column:is_current;index;not null;default:false"`
	CreateTime  time.Time `gorm:"column:create_time;autoCreateTime"`
	UpdateTime  time.Time `gorm:"column:update_time;autoUpdateTime"`
}

func (UserAvatarHistory) TableName() string {
	return "user_avatar_history"
}
