require "logger"
# Liste des id constants dans la BDD

# LETTRE DES IDENTIFIANT POUR L'ENT DU RHONE
LETTRE_PROJET_LACLASSE = "V"
CHIFFR_PROJET_LACLASSE = "6"

#
# TypeTelephone
# 
TYP_TEL_MAIS = "MAISON"
TYP_TEL_PORT = "PORTABLE"
TYP_TEL_TRAV = "TRAVAIL"
TYP_TEL_FAX  = "FAX"
TYP_TEL_AUTR = "AUTRE"

#
# TypeRelationEleve
#
TYP_REL_PERE  		 = 1
TYP_REL_MERE  	     = 2
TYP_REL_TUT          = 3
TYP_REL_AUTRE_MEMBRE = 4
TYP_REL_DDASS        = 5
TYP_REL_AUTRE_CAS    = 6
TYP_REL_ELV_LUI      = 7

#
# TypeRegroupement
#
# TYP_REG_CLS = "CLASSE"
# TYP_REG_GRP = "GROUPE"
# TYP_REG_LBR = "LIBRE"

TYP_REG_CLS = "CLS"
TYP_REG_GRP = "GRP"
TYP_REG_LBR = "LBR"

#
# TypeEtablissement
#
TYP_ETB_CTR_PU = "PU"

#
# Service
#
SRV_LACLASSE = "LACLASSE"
SRV_ETAB     = "ETAB"

#Todo: change this to class names 
# Le nom des service de regroupement est le même que les types de regroupement
SRV_CLASSE   = "CLASSE"
SRV_GROUPE   = "GROUPE"
SRV_LIBRE    = "LIBRE"
SRV_USER     = "USER"

#
# Profil
# TODO : add more profiles from profil_national_table
#
PRF_ELV = "ELV"
PRF_ENS = "ENS"
PRF_DIR = "DIR"
PRF_PAR = "TUT"
PRF_ADM = "ETA"

#
# Role
#
ROL_TECH = "TECH"
ROL_ELV_ETB = "ELV_ETB"
ROL_PROF_ETB = "PROF_ETB"
ROL_ADM_ETB = "ADM_ETB"
ROL_PAR_ETB = "PAR_ETB"
ROL_DIR_ETB = "DIR_ETB"
ROL_CPE_ETB = "CPE_ETB"
ROL_BUR_ETB = "BUR_ETB"

ROL_PROF_CLS = "PROF_CLS"
ROL_ELV_CLS = "ELV_CLS"
ROL_PRFP_CLS = "PRFP_CLS"

#
# Activite
#
ACT_CREATE = "CREATE"
ACT_READ   = "READ"
ACT_UPDATE = "UPDATE"
ACT_DELETE = "DELETE"
ACT_MANAGE = "MANAGE"

#
# TypeParam
#
TYP_PARAM_BOOL = "BOOLEAN"
TYP_PARAM_TEXT = "TEXT"
TYP_PARAM_NUMBER = "NUMBER"
