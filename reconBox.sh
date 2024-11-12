#!/bin/bash

# Colores
verde="\e[0;32m\033[1m"
finColor="\033[0m\e[0m"
rojo="\e[0;31m\033[1m"
azul="\e[0;34m\033[1m"
amarillo="\e[0;33m\033[1m"
morado="\e[0;35m\033[1m"
tuquesa="\e[0;36m\033[1m"
gris="\e[0;37m\033[1m"

# Variables
ip="$1"
name="$2"
validation=$(ping -c 1 $ip | grep received | awk '{print $4}')

# Estado de la Conexión
if [ $validation -eq 1 ]; then
    echo -e "\n${verde}[+] Estado de la conexión: ${azul}Conectado${finColor}${verde}"

    # Reporte de sistema operativo
    so="$(wichSystem.py $ip | awk '{print $5}' | column)"
    
    if [[ $so = "Linux" || $so = "Windows" ]]; then
        echo -e "\n[+] Sistema Operativo = ${azul}$so${finColor}${verde}"
    else
        echo -e "\n[+] Sistema Operativo Desconocido."
    fi

    # Nmpa - En caso de que portScan exista ya o no.

    echo -e "\n[+] Ecaneando archivos con Nmap:"

    if [ -e "./portScan" ]; then 
        echo -e "\n    [+] El archivo ${azul}portScan${verde} ya existe, desea volver a realizar el Escaneo? [s/n]"
        read respuesta
        if [ "$respuesta" = "s" ]; then
            echo -e "\n    [+] Escaneando puertos abiertos:"

            # Escaneo básico con Nmap:    
            sudo nmap -p- -sS --open --min-rate 5000 -v -n $ip -oG portScan 2&>/dev/null
            echo -e "\n    [+] Archivo ${azul}portScan${finColor}${verde} creado."
        else
            echo -e "\n    [+] Ecaneo no realizado."
        fi        
    else
        echo -e "\n    [+] Escaneando puertos abiertos:"

        # Escaneo básico con Nmap:    
        sudo nmap -p- -sS --open --min-rate 5000 -v -n $ip -oG portScan 2&>/dev/null
        echo -e "\n    [+] Archivo ${azul}portScan${finColor}${verde} creado."
    fi
    
    ports="$(cat portScan | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')" 
    echo -e "\n    [+] Puertos abiertos: ${azul}$ports${finColor}${verde}"

    if [ -e "./infoScan" ]; then
        echo -e "\n    [+] El archivo ${azul}infoScan${verde} ya existe, desea volver a realizar el Escaneo? [s/n]"
        read respuesta
        if [ "$respuesta" = "s" ]; then
            echo -e "\n    [+] Escaneando puertos abiertos: \n"
            # Ecaneo de puertos abiertos con Nmap:
            nmap -sC -sV -n -v -p $ports $ip -oN infoScan 2&>/dev/null
            targed=$(cat infoScan | sed -n '6,$p' | head -n -3)
        fi
    else
    # Ecaneo de puertos abiertos con Nmap:
    nmap -sC -sV -n -v -p $ports $ip -oN infoScan 2&>/dev/null
    targed=$(cat infoScan | sed -n '6,$p' | head -n -3)
    fi
    targed=$(cat infoScan | sed -n '6,$p' | head -n -3)
    
    echo -e "\n    [+] Quíeres ver el archivo ${azul}infoScan${verde} [s/n]" 
    read respuesta1    
    if [ "$respuesta1" = "s" ]; then
            echo -e "${azul}$targed${verde} \n"
   fi

    # Información por puertos encontrados:
    # Puerto 21
    if [[ "$ports" == *"21"* ]]; then
        echo -e "\n${verde}[+] Analizando Puerto ${azul}21 ftp${finColor}${verde} encontrado: \n"
        sudo ftp $ip
    fi
   
    # Puerto 22
    if [[ "$ports" == *"22"* ]]; then
        echo -e "\n${verde}[+] Analizando Puerto ${azul}22 ssh${finColor}${verde} encontrado: \n"
        sudo ftp $ip
    fi

    # Puerto 80 
    if [[ "$ports" == *"80"* ]]; then
        echo -e "\n${finColor}${verde}[+] Analizando Puerto ${azul}80 http${finColor}${verde} encontrado: \n"
        # Whatweb Ip
        sudo whatweb "$ip"
        report=$?

        if [ $report -eq "0"  ]; then
            # WFUZZ IP
            echo -e "\n${verde}[+] Realizar Fuzzing ${azul}http://$ip/FUZZ${finColor}${verde}: [s/n] \n"
            read respuesta2
            if [ "$respuesta2" = "s" ]; then
                wfuzz -w /usr/share/wordlists/directory-list-2.3-big.txt --hc 404 http://$ip/FUZZ
            fi
        fi

        echo -e "\n[+] Resolviendo Virtual Hosting: ${azul}$ip $name.htb --> /etc/hosts ${finColor}${verde}\n"

        sudo echo "$ip $name.htb" >> /etc/hosts

        # Whatweb Virtual Hosting
        sudo whatweb "$name.htb"
        report=$?
        if [ $report -eq "0"  ]; then
            # WFUZZ Virtual Hosting
            echo -e "\n${verde}[+] Realizar Fuzzing ${azul}http://$name.htb/FUZZ${finColor}${verde}: [s/n] \n"
            read respuesta3
            if [ "$respuesta3" = "s" ]; then
                wfuzz -w /usr/share/wordlists/directory-list-2.3-big.txt --hc 404 http://$name.htb/FUZZ
            fi
        fi

    fi

    # Puerto 443    
    if [[ "$ports" == *"443"* ]]; then
        echo -e "\n${verde}[+] Analizando Puerto ${azul}443 http${finColor}${verde} encontrado:"
        sudo whatweb "$ip"
    fi
        
    # Puerto 873    
    if [[ "$ports" == *"873"* ]]; then
        echo -e "\n${verde}[+] Analizando Puerto ${azul}873 Rsync${finColor}${verde} encontrado: \n"
        echo -e "\n   [+] Directorios encontrados en la base de datos: ${azul} \n"
        rsync $ip::
        
    fi

    # Puerto 27017    
    if [[ "$ports" == *"27017"* ]]; then
        echo -e "\n${verde}[+] Analizando Puerto ${azul}27017 MongoDB${finColor}${verde} encontrado:"
        mongodump --host $ip --port 27017
        echo -e "\n[+] La base de datos MognoDB se ha descargado y guardado con el nombre de: ${azul}dump${verde}"
        rutaflag="$(find ./dump | grep flag.bson)"

        if [[ -n "$rutaflag" ]]; then
            echo -e "\n[+] Hemos encontrado la palabra flag en la siguiente ruta:\n\n ${azul}${rutaflag}${verde}"
            catRutaFlag=$(cat $rutaflag | tr -d '\0')
            echo -e "\n[+] Con el siguiente cotenido:"
            echo -e "\n ${azul}$catRutaFlag${verde}"
        fi     
    fi
else
    echo -e "\n[+] No se ha podido establecer la conexión. \n"
fi

# By: TERRITORIO HACKER - Firox


