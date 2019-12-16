/*----------------------------------------------------------------------------------------
PROGRAMME PROMELA : SYSTEME DE CONTROLE D UN ASCENSEUR
----------------------------------------------------------------------------------------*/

#define NB_ETAGES 10 /*Nombre d'étages dans le batiment*/

mtype:DIRECTION_ASC = {MONTER,DESCENDRE};
mtype:PORTES = {OUVERTES,FERMEES,OUVRIR,FERMER};

//bool tableauMonter[NB_ETAGES] = false;

typedef chEtage {
	chan canal = [1] of {mtype:DIRECTION_ASC};
}

chEtage ChEtages_MONTER[NB_ETAGES];
chEtage ChEtages_DESCENDRE[NB_ETAGES];

chan chCmdAscenseur = [1] of {mtype:DIRECTION_ASC, int} ;
chan chDeplacerAsc = [1] of {mtype:DIRECTION_ASC, int};// demande directe du controleur
chan chPortes = [1] of {mtype:PORTES};

int etageAscCourant = 0;
mtype:DIRECTION_ASC sensAscCourant = MONTER;

active proctype Controleur() {//todo: apres ascenseur arrive, effacer la commande dans le channel ChEtages_MONTER/DESCENDRE
	int nb, max_descente, min_montee = NB_ETAGES -1;
	int etagePasse;
	do
	::else
		max_descente = 0; min_montee = NB_ETAGES -1;
		montees:
		for(nb :  0 .. (NB_ETAGES-1)){
			if
			::ChEtages_MONTER[nb].canal?[MONTER] -> if
													::(nb >= etageAscCourant) -> chCmdAscenseur!MONTER(nb);	
													::else if
														   ::nb < min_montee -> min_montee = nb
														   ::else	
														   fi
													fi
			::else													
			fi
		}
		descentes:
		for(nb :  0 .. (NB_ETAGES-1)){
			if
			::ChEtages_DESCENDRE[NB_ETAGES - (nb+1)].canal?[DESCENDRE] ->
															if
															::(NB_ETAGES - (nb+1) <= etageAscCourant) -> chCmdAscenseur!DESCENDRE(NB_ETAGES - (nb+1));	
															::else if 
																   ::NB_ETAGES - (nb+1) > max_descente -> max_descente = NB_ETAGES - (nb+1)
																   ::else
																   fi
															fi
			::else
			fi
		}

		//traiter les montees ignorees
		if
		::(etageAscCourant > min_montee) -> chDeplacerAsc!DESCENDRE(min_montee);
		::(etageAscCourant < max_descente) -> chDeplacerAsc!MONTER(max_descente);
		::else
		fi

	od
};

active proctype Ascenseur() { //todo: apres ascenseur arrive, effacer la commande dans le channel
	mtype:DIRECTION_ASC sensAsc;
	int etageCmd;
debut:
	do
	::chCmdAscenseur?<sensAsc, etageCmd> -> 
			printf("commande etage%d %e\n", etageCmd, sensAsc);
	arriveeEtage:
			if
			::(etageCmd == etageAscCourant) -> chCmdAscenseur?sensAsc, etageCmd; 
											   if
											   :: (sensAsc == MONTER) -> ChEtages_MONTER[etageCmd].canal?sensAsc ; 
											   :: (sensAsc == DESCENDRE ) -> ChEtages_DESCENDRE[etageCmd].canal?sensAsc ;
											   fi
											   printf("ouverture des portes etage%d\n", etageCmd);
					
			::(etageCmd != etageAscCourant) -> printf("deplacement de etage%d vers etage%d\n", etageAscCourant, etageCmd); 
											   if
											   ::(sensAsc == MONTER) -> etageAscCourant ++;
											   ::(sensAsc == DESCENDRE) -> etageAscCourant --;
											   fi											   		
											   goto arriveeEtage;	   
			fi	

	::chDeplacerAsc?sensAsc, etageCmd -> printf("deplacement special de etage%d vers etage%d\n", etageAscCourant, etageCmd); 
										 etageAscCourant = etageCmd; goto debut
	od
};

active proctype Portes(){
	Fermees: 	chPortes?OUVRIR; printf("Les portes s'ouvrent ...\n"); chPortes!OUVERTES;
	Ouvertes:	chPortes?FERMER; printf("Les portes se ferment ...\n"); chPortes!FERMEES; goto Fermees;
}

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
	 run Utilisateur(5, MONTER); 
	 run Utilisateur(7, DESCENDRE);
	 run Utilisateur(3, DESCENDRE);
	 run Utilisateur(6, MONTER); 

	 run Utilisateur(9, DESCENDRE);

	 run Utilisateur(0, MONTER); 
	 run Utilisateur(7, MONTER);

	 //run Utilisateur(1, MONTER); 
	 //run Utilisateur(3, DESCENDRE);

	 //run Utilisateur(6, MONTER);
	 //run Utilisateur(6, MONTER);
	 //run Utilisateur(1, DESCENDRE);
};

