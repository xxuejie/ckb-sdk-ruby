#include <stdio.h>
#include <secp256k1.h>
#include <secp256k1_recovery.h>

int char_to_int(char ch)
{
  if (ch >= '0' && ch <= '9') {
    return ch - '0';
  }
  if (ch >= 'a' && ch <= 'f') {
    return ch - 'a' + 10;
  }
  return -1;
}

int hex_to_bin(char* buf, size_t buf_len, const char* hex)
{
  int i = 0;

  for (; i < buf_len && hex[i * 2] != '\0' && hex[i * 2 + 1] != '\0'; i++) {
    int a = char_to_int(hex[i * 2]);
    int b = char_to_int(hex[i * 2 + 1]);

    if (a < 0 || b < 0) {
      return -1;
    }

    buf[i] = ((a & 0xF) << 4) | (b & 0xF);
  }

  if (i == buf_len && hex[i * 2] != '\0') {
    return -1;
  }
  return i;
}

int main(int argc, char* argv[]) {
  unsigned char private_key[32];
  if (argc != 2) {
    printf("Usage: %s <private key in hex with 0x>\n", argv[0]);
    return -100;
  }

  int ret = hex_to_bin((char*)private_key, 32, argv[1] + 2);
  if (ret != 32) {
    return -101;
  }
  
  secp256k1_context *context = secp256k1_context_create(SECP256K1_CONTEXT_SIGN);
  if (context == NULL) {
    return -103;
  }
  
  secp256k1_pubkey pubkey;
  ret = secp256k1_ec_pubkey_create(context, &pubkey, private_key);
  if (ret != 1) {
    secp256k1_context_destroy(context);
    return -104;
  }

  unsigned char output[33];
  size_t len = 33;
  ret = secp256k1_ec_pubkey_serialize(context, output, &len, &pubkey, SECP256K1_EC_COMPRESSED);
  if (ret != 1) {
    secp256k1_context_destroy(context);
    return -105;
  }
  
  printf("Public key: 0x");
  for (int i = 0; i < len; i++) {
    printf("%02x", output[i]);
  }
  printf("\n");
  
  return 0;
}
