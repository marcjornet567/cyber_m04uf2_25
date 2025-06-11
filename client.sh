#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Error: El comando requiere al menos un parámetro"
  echo "Ejemplo de uso:"
  echo "$0 127.0.0.1"
  exit 1
fi

PORT=7777
IP_SERVER="$1"
IP_CLIENT=$(ip a | grep -w -i inet | grep -i enp0s3 | awk '{print $2}' | cut -d "/" -f 1)
echo "LSTP Client (Lechuga Speaker Transfer Protocol)"

echo "1. SEND HEADER"

echo "LSTP_1 $IP_CLIENT" | nc $IP_SERVER $PORT

echo "2.LISTEN OK_HEADER"

DATA=$(nc -l $PORT)

echo "6.CHECK OK_HEADER"
if [ "$DATA" != "OK_HEADER" ]; then
  echo "ERROR 1: Header enviado incorrectamente"
  exit 1
fi

echo "7.SEND FILE_NAME"

echo "FILE_NAME audio_file.ogg" | nc $IP_SERVER $PORT

echo "8.LISTEN"

DATA=$(nc -l $PORT)

if [ "$DATA" != "OK_FILE_NAME" ]; then
  echo "ERROR 2: FILE_NAME mal enviado"
  exit 2
fi

echo "12. SEND FILE DATA"
cat audio_file.ogg | nc $IP_SERVER $PORT

echo "13.LISTEN OK/KO_FILE_DATA"
DATA=$(nc -l $PORT)

if [ "$DATA" != "OK_FILE_DATA" ]; then
  echo "ERROR 3: Error al enviar los datos"
  exit 3
fi

echo "16. SEND FILE_DATA_MD5"

MD5=$(cat audio_file.ogg | md5sum | cut -d " " -f 1)

echo "FILE_DATA_MD5 $MD5" | nc $IP_SERVER $PORT

echo "17. LISTEN FILE_DATA_MD5"
DATA=$(nc -l $PORT)

echo "21. CHECK OK_FILE_MD5"
if [ "$DATA" != "OK_FILE_MD5" ]; then
  echo "ERROR 4: El MD5 no coincide"
  exit 4
fi

echo "Fin"
exit 0
