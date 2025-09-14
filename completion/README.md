# Cairo Coder

> [site](https://www.cairo-coder.com)
>
> [docs](https://www.cairo-coder.com/docs)

## .env management

1. compress

```shell
gpg --symmetric --cipher-algo AES256 .env
```

2. decompress

```shell
gpg --decrypt .env.gpg > .env
```

3. shell script

```shell
./env-encrypt.sh
```

## generate

1. using curl

```shell
curl -X POST "https://api.cairo-coder.com/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{
    "messages": [
      {
        "role": "user",
        "content": "Write a simple Cairo contract that implements a counter"
      }
    ]
  }'
```

2. using rust

```shell
cargo run
```
