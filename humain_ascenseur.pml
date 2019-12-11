/*----------------------------------------------------------------------------------------
PROGRAMME PROMELA : SYSTEME DE CONTROLE D UN ASCENSUR
----------------------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------------------
Les constantes
----------------------------------------------------------------------------------------*/
#define MAX 1000 //
#define timerTpsAttenteMax 20
#define appelAscMax  18 //Le nombre maximal d'appels simultanés à l'ascenseur 2*nbEtages - 2
#define fermerPortes 20 //commande fermer les portes de l'ascenseur
#define ouvrirPortes 21 //commande ouvrir les portes de l'ascenseur
#define persMax 5 //nombre maximal de personnes dans l'ascenseur




/*----------------------------------------------------------------------------------------
Les declarations
----------------------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------------------
Les varialbes
----------------------------------------------------------------------------------------*/
mtype = {//todo: mettre de l'ordre
	SIGNAL_PRESENCE, UTILISATEUR_INTERIEUR_ASCENSEUR, // présence de l'utilisateur
	SIGNAL_OUVRIR_PORTES, SIGNAL_PORTES_OUVERTES, // états des portes de l'ascenseur
	SIGNAL_FERMER_PORTES, SIGNAL_PORTES_FERMEES,  // commandes des portes de l'ascenseur
	SIGNAL_TIMER_INIT, SIGNAL_TIMEOUT, SIGNAL_APPEL_ASC, // etc ... etc
	SIGNAL_DETECTER_PERSONNE, SIGNAL_DEPLAC_ASC, SIGNAL_PRESENCE_ETAGE
};

mtype:position = {etage0, etage1, etage2, etage3, etage4, etage5, etage6, etage7,
				   etage8, etage9 } ;//dix etages pour notre bâtiment

mtype:sensDepl = {monter, descendre}; //sens de déplacement de l'ascenseur


int cptTimer;
int nbrePersonneDansAscenseur;
mtype:position etageCourantAsc;
bool porteAscOuverte = 0;

bool ascPresent = 0; //ascenceur present à l'étage desire

/*----------------------------------------------------------------------------------------
Les canaux
----------------------------------------------------------------------------------------*/
chan chPresence = [0] of {mtype};
chan chTimer = [0] of {mtype};
chan chCtrl = [0] of {mtype};
chan chPortes = [1] of {mtype};
//chan chAsc = [...] of {mtype};

chan chDetectionEntree = [persMax] of {mtype};


chan chAppelAscenseur = [appelAscMax] of { mtype:position, mtype:sensDepl }; //appels à l'ascenseur de l'extérieur
chan chBoutonInterieur = [MAX]  of { int }; //commandes envoyées à l'utilisateur


//S'assurer que les boutons de numéro d'étage sont entre 0 et N-1


/*----------------------------------------------------------------------------------------
Les processus
----------------------------------------------------------------------------------------*/
/* ----------------------------
  Ascenseur 
---------------------------- */

/* ----------------------------
  Utilisateur
---------------------------- */

proctype Utilisateur( mtype:position etageUtilisateur; mtype:sensDepl sens) {
	
	
	if //si l'ascenseur est là, l'utilisateur y entre
	:: (etageUtilisateur == etageCourantAsc) && porteAscOuverte -> goto entrerDansAsc;

	:: else //appelle l'ascenseur pour monter ou descendre
			if//écriture si un message du même genre n'existe pas déjà
		    ::!(chAppelAscenseur??[etageUtilisateur, sens]) -> chAppelAscenseur!etageUtilisateur, sens;  
			:: else
			fi;
			do //attends l'ascenseur
			:: (etageUtilisateur == etageCourantAsc) && porteAscOuverte -> break;
			od
	fi

	entrerDansAsc: chDetectionEntree!UTILISATEUR_INTERIEUR_ASCENSEUR;
	
};


init{
	run Utilisateur(etage0, monter);
}
