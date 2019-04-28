FROM golang:1.12.4-alpine3.9

WORKDIR /go/src/ghux
COPY . .

RUN apk add --no-cache git mercurial \
	&& go get github.com/mitchellh/go-homedir \
	&& go get github.com/spf13/cobra \
	&& go get github.com/spf13/viper

RUN apk del git mercurial
CMD ["go", "run", "main.go"]

