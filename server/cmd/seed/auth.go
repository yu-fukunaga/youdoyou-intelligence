package main

import (
	"context"
	"fmt"
	"log"

	"firebase.google.com/go/v4/auth"
)

// SeedAuthUser defines a Firebase Auth user to create in the emulator.
type SeedAuthUser struct {
	UID         string
	Email       string
	Password    string
	DisplayName string
	PhotoURL    string
}

// SeedAuthUsers creates the defined users in Firebase Auth.
func SeedAuthUsers(ctx context.Context, client *auth.Client) error {
	log.Println("Seeding Auth users...")

	for _, u := range authUserSeeds {
		if _, err := client.GetUser(ctx, u.UID); err != nil {
			if !auth.IsUserNotFound(err) {
				return fmt.Errorf("error checking auth user %s (UID: %s): %w", u.Email, u.UID, err)
			}
			log.Printf("Auth user %s (UID: %s) not found, creating...\n", u.Email, u.UID)
		} else {
			log.Printf("Auth user %s (UID: %s) already exists, skipping.\n", u.Email, u.UID)
			continue
		}

		params := (&auth.UserToCreate{}).
			UID(u.UID).
			Email(u.Email).
			Password(u.Password).
			DisplayName(u.DisplayName).
			PhotoURL(u.PhotoURL)

		if _, err := client.CreateUser(ctx, params); err != nil {
			return err
		}
		log.Printf("Successfully created auth user: %s\n", u.Email)
	}
	return nil
}
