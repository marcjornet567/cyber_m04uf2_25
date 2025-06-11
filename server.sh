#!/bin/bash

PORT=7777

echo "LSTP Server (Lechuga Speaker Transfer Protocol)"

echo "0. LISTEN"

DATA=$(nc -l $PORT)

echo "3.CHECK"

HEADER=$(echo "$DATA" | cut -d " " -f 1)

if [ "$HEADER" != "LSTP_1" ]; then
  echo "ERROR 1: Header mal formado $DATA"
  echo "KO_HEADER" | nc $IP_CLIENT $PORT
  exit 1
fi

IP_CLIENT=$(echo "$DATA" | cut -d " " -f 2)

echo "4.SEND OK_HEADER"

echo "OK_HEADER" | nc $IP_CLIENT $PORT

echo "5.LISTEN FILE_NAME"

DATA=$(nc -l $PORT)

echo "9.CHECK FILE_NAME"

PREFIJO=$(echo $DATA | cut -d " " -f 1)

if [ "$PREFIJO" != "FILE_NAME" ]; then
  echo "ERROR 2: FILE_NAME incorrecto"
  echo "KO_FILE_NAME" | nc $IP_CLIENT $PORT
  exit 2
fi

FILE_NAME=$(echo $DATA | cut -d " " -f 2)

echo "10. SEND OK_FILE_NAME"

echo "OK_FILE_NAME" | nc $IP_CLIENT $PORT

echo "11. LISTEN FILE DATA"

nc -l $PORT >server/$FILE_NAME

echo "14. SEND OK_FILE_DATA"

DATA=$(cat server/$FILE_NAME | wc -c)

if [ $DATA -eq 0 ]; then
  echo "ERROR 3: Datos mal formados (vacíos)"
  echo "KO_FILE_DATA" | nc $IP_CLIENT $PORT
  exit 3
fi

echo "OK_FILE_DATA" | nc $IP_CLIENT $PORT

echo "15. LISTEN FILE_MD5"

DATA=$(nc -l $PORT)
echo $DATA

echo "18. COMPROBACION PREFIJO_MD5 RECIBIDO DEL CLIENTE"

PREFIJO_MD5=$(echo $DATA | cut -d " " -f 1)

if [ "$PREFIJO_MD5" != "FILE_DATA_MD5" ]; then
  echo "ERROR 5: Prefijo MD5 incorrecto"
  echo "KO_FILE_DATA_MD5" | nc $IP_CLIENT $PORT
  exit 5
fi

echo "19. COMPROBACIÓN INTEGRIDAD MD5 RECIBIDO DEL CLIENTE"

MD5_SERVER=$(cat "server/$FILE_NAME" | md5sum | cut -d " " -f 1)
MD5_CLIENTE=$(echo $DATA | cut -d " " -f 2)

if [ "$MD5_CLIENTE" != "$MD5_SERVER" ]; then
  echo "ERROR 6: El MD5 no coincide"
  echo "KO_FILE_DATA_MD5" | nc $IP_CLIENT $PORT
  exit 6
fi

echo "20. SEND OK_FILE_MD5"

echo "OK_FILE_MD5" | nc $IP_CLIENT $PORT

echo "Fin"
exit 0
