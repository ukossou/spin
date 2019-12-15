/*----------------------------------------------------------------------------------------
PROGRAMME PROMELA : SYSTEME DE CONTROLE D UN ASCENSEUR
----------------------------------------------------------------------------------------*/

#define NB_ETAGES 10 /*Nombre d'étages dans le batiment*/

mtype:DIRECTION_ASC = {MONTER,DESCENDRE};

//bool tableauMonter[NB_ETAGES] = false;

typedef chEtage {
	chan canal = [1] of {mtype:DIRECTION_ASC};
}

chEtage ChEtages_MONTER[NB_ETAGES];

active proctype Controleur() {
    skip;
};

active proctype Ascenseur() {
	skip;
};


proctype Utilisateur(int etage; mtype:DIRECTION_ASC sens) {
	printf("utilisateur%d arrive etage%d\n", _pid, etage);
	if
	::ChEtages_MONTER[etage].canal!MONTER -> printf("utilisateur%d etage%d appelle ascenseur %e\n", _pid, etage, sens);
	::ChEtages_MONTER[etage].canal?[MONTER] -> goto attenteAsc;
	fi

	attenteAsc: printf("utilisateur%d etage%d attend ascenseur\n", _pid, etage);
};


init{
	run Utilisateur(0, MONTER);
	 run Utilisateur(0, MONTER);
	 run Utilisateur(0, MONTER); 
	 run Utilisateur(0, MONTER);
};

