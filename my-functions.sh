#!/usr/bin/env bash
# Optionally declare here custom functions/variables to use in commands and hooks
# Prefix them in order to avoid conflicts
# You can also source other external files
read_file()
{
nl ~/liste.txt
}

jv_pg_pluie_lang () {
    case "$1" in
        no_data) echo "Pas de données disponibles.";;
        already_raining) echo "Il pleut déjà, ou il va pleuvoir dans les 5 prochaine minutes.";;
        rain_in) echo "Il va probablement pleuvoir dans approximativement $2 minutes.";;
        no_rain) echo "Pas de pluie prévue dans l'heure.";;
    esac
} 

pluie_dans_une_heure()
{
	local sum=0
	local has_unknowns=false
	local has_rain=false
	local iteration=0
	local iter_of_first_rain=0
	local code_insee='940760'
	
	local infos="$(curl -s http://www.meteofrance.com/mf3-rpc-portlet/rest/pluie/${code_insee} | jq '.["dataCadran"][]["niveauPluie"]')"
	jv_debug $infos
	
	for row in $infos; do
		if [ $row -eq 0 ]
		then
			has_unknowns=true
		fi
		
		if [ $row -ge 2 ] && ! $has_rain
		then
			has_rain=true
			iter_of_first_rain=$iteration
		fi
		
		let iteration=iteration+1
		let sum=sum+row
	done


	if [ $sum -eq 0 ]
	then
		say "$(jv_pg_pluie_lang no_data)"
		return 0
	fi
	
	if $has_rain && [ $iter_of_first_rain -eq 0 ]
	then
		say "$(jv_pg_pluie_lang already_raining)"
		return 0
	fi
	
	if $has_rain
	then
		say "$(jv_pg_pluie_lang rain_in $((5*$iter_of_first_rain)))"
		return 0
	fi
	
	say "$(jv_pg_pluie_lang no_rain)"
	return 0

}

