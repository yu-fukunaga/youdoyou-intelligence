package generator

import _ "embed"

//go:embed template/Package.swift
var PackageSwiftTemplate []byte
