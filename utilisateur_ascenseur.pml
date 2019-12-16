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
chEtage ChEtages_DESCENDRE[NB_ETAGES];

chan chAsCmdAscenseur = [1] of {mtype:DIRECTION_ASC, int} ;

int etageAscCourant = 0;
mtype:DIRECTION_ASC sensAscCourant = MONTER;

active proctype Controleur() {
	int nb;
    for(nb :  0 .. (NB_ETAGES-1)){
		if
		::ChEtages_MONTER[nb].canal?[MONTER] -> if
												::(nb >= etageAscCourant) -> chAsCmdAscenseur!MONTER(nb);	
												::else
												fi
		::else													
		fi
	}
};

active proctype Ascenseur() {
	mtype:DIRECTION_ASC sensAsc;
	int etageCmd; //etageCourant;

	do
	::chAsCmdAscenseur?<sensAsc, etageCmd> -> printf("commande etage%d %e\n", etageCmd, sensAsc);
											  etageAscCourant = etageCmd;
											  chAsCmdAscenseur?sensAsc, etageCmd
	od
};


proctype Utilisateur(int etage; mtype:DIRECTION_ASC sens) {
	//printf("utilisateur%d arrive etage%d\n", _pid, etage);
	if
	::(sens == MONTER) -> if
						  ::ChEtages_MONTER[etage].canal!MONTER -> skip  //printf("utilisateur%d etage%d appelle ascenseur %e\n", _pid, etage, sens);
						  ::ChEtages_MONTER[etage].canal?[MONTER] -> goto attenteAsc;
						  fi

	::(sens == DESCENDRE) -> if
						  	::ChEtages_DESCENDRE[etage].canal!DESCENDRE -> skip //printf("utilisateur%d etage%d appelle ascenseur %e\n", _pid, etage, sens);
						  	::ChEtages_DESCENDRE[etage].canal?[DESCENDRE] -> goto attenteAsc;
						  	fi

	fi

	attenteAsc: //printf("utilisateur%d etage%d attend ascenseur %e\n", _pid, etage, sens);
};


init{
	 run Utilisateur(1, MONTER);
	 run Utilisateur(1, DESCENDRE);

	 run Utilisateur(1, MONTER); 
	 run Utilisateur(5, DESCENDRE);

	 run Utilisateur(1, MONTER); 
	 run Utilisateur(1, DESCENDRE);

	 run Utilisateur(6, MONTER);
	 run Utilisateur(6, MONTER);
	 run Utilisateur(1, DESCENDRE);
};

