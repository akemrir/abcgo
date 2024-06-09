BIN          := abcgo
VERSION      := v1.0.1
MAKEFILE     := $(realpath $(lastword $(MAKEFILE_LIST)))
ROOT_DIR     := $(shell dirname $(MAKEFILE))
SOURCES      := $(wildcard *.go src/*.go src/*/*.go) $(MAKEFILE)
REVISION     := $(shell git log -n 1 --pretty=format:%h -- $(SOURCES) 2> /dev/null)
AUTHOR       := $(shell git config user.email 2> /dev/null)
MACHINE      := $(shell hostname 2> /dev/null)
TIME         := $(shell LANG=EN date 2> /dev/null)
MAIN_PACKAGE := git.sliceofcode.eu/akemrir/commander

A := $(MAIN_PACKAGE)/settings.Author=$(AUTHOR)
V := $(MAIN_PACKAGE)/settings.Version=$(VERSION)
R := $(MAIN_PACKAGE)/settings.Revision=$(REVISION)
M := $(MAIN_PACKAGE)/settings.Machine=$(MACHINE)
T := $(MAIN_PACKAGE)/settings.Time=$(TIME)

TAGS := ""
# BUILD_FLAGS    := -a -ldflags "-n -s -w -X $(A) -X $(V) -X $(R) -X $(M) -X \"$(T)\"" -tags "$(TAGS)" -gcflags=-trimpath=${GOPATH} -asmflags=-trimpath=${GOPATH} -trimpath
BUILD_FLAGS    := -ldflags "-n -s -w -X $(A) -X $(V) -X $(R) -X $(M) -X \"$(T)\"" -tags "$(TAGS)" -gcflags=-trimpath=${GOPATH} -asmflags=-trimpath=${GOPATH} -trimpath
ifeq ($(REVISION),)
$(error Not on git repository; cannot determine $$REVISION)
endif

build-dev:
	go build -o $(BIN) ./main.go

build:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(BUILD_FLAGS) -o $(BIN) ./main.go
	cp $(BIN) $(BIN).$(shell date +%Y%m%d.%H%M)

upgrade:
	# cd cmd/com && go get -u
	go get -u ./...
	go mod tidy
	go mod vendor

deploy: build dist install

upx: build
	upx --best $(BIN)

dist:
	cp $(BIN) ~/code/dist

install:
	sudo install $(BIN) -t /usr/local/bin

elf:
	readelf -lSW $(BIN)

dump:
	objdump -x $(BIN)

push:
	git push origin master --tags
	git push git master --tags

cover:
	go test -v -coverprofile cover.out ./...
	go tool cover -func=cover.out

bench:
	go test -bench=. -benchmem -count=10 >bench.txt
	benchstat bench.txt

bench_2:
	go test -bench=. -benchtime=10s -benchmem
