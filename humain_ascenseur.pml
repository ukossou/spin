/*----------------------------------------------------------------------------------------
PROGRAMME PROMELA : SYSTEME DE CONTROLE D UN ASCENSUR
----------------------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------------------
Les constantes
----------------------------------------------------------------------------------------*/
#define MAX 1000 //
#define timerTpsAttenteMax 20
#define appelAscMax  18 //Le nombre maximal d'appels simultanes a l'ascenseur 2*nbEtages - 2
//#define fermerPortes 20 //commande fermer les portes de l'ascenseur
//#define ouvrirPortes 21 //commande ouvrir les portes de l'ascenseur
#define persMax 5 //nombre maximal de personnes dans l'ascenseur




/*----------------------------------------------------------------------------------------
Les declarations
----------------------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------------------
Les varialbes
----------------------------------------------------------------------------------------*/
mtype = {//todo: mettre de l'ordre
	SIGNAL_PRESENCE, UTILISATEUR_INTERIEUR_ASCENSEUR, // presence de l'utilisateur
	SIGNAL_OUVRIR_PORTES, SIGNAL_PORTES_OUVERTES, // etats des portes de l'ascenseur
	SIGNAL_FERMER_PORTES, SIGNAL_PORTES_FERMEES,  // commandes des portes de l'ascenseur
	SIGNAL_TIMER_INIT, SIGNAL_TIMEOUT, SIGNAL_APPEL_ASC, // etc ... etc
	SIGNAL_DETECTER_PERSONNE, SIGNAL_DEPLAC_ASC, SIGNAL_PRESENCE_ETAGE
};

mtype:position = {etage0, etage1, etage2, etage3, etage4, etage5, etage6, etage7,
				   etage8, etage9 } ;//dix etages pour notre batiment

//mtype:boutonsDansAsc = {position, ouvrir, fermer};

mtype:sensDepl = {monter, descendre}; //sens de deplacement de l'ascenseur

mtype:etatPorte = { ouverte, fermee }//etats possibles des portes de l'ascenseur


int cptTimer;
int nbrePersonneDansAscenseur;
mtype:position etageCourantAsc = etage0;
mtype:etatPorte etatPorteAsc = fermee;

/*----------------------------------------------------------------------------------------
Les canaux
----------------------------------------------------------------------------------------*/
chan chPresence = [0] of {mtype};
chan chTimer = [0] of {mtype};
chan chCtrl = [0] of {mtype};
chan chPortes = [1] of {mtype};
//chan chAsc = [...] of {mtype};

chan chDetectionEntree = [persMax] of {mtype};


chan chAppelAscenseur = [appelAscMax] of { mtype:position, mtype:sensDepl }; //appels a l'ascenseur (de l'exterieur)
chan chCommandeAsc = [1] of { mtype:position, mtype:sensDepl };//commande envoyee a l'asc par le controleur
//chan chBoutonInterieur = [MAX]  of { int }; //commandes envoyees a l'utilisateur


//S'assurer que les boutons de numero d'etage sont entre 0 et N-1


/*----------------------------------------------------------------------------------------
Les processus
----------------------------------------------------------------------------------------*/
/* ----------------------------
  Controleur
---------------------------- */

active proctype Controleur() {
    
	 mtype:position etage; 
	 mtype:sensDepl sens;
	
	 //copier le message a partir du canal chAppelAscenseur
	 //envoyer l'ordre a l'ascenseur
	 //recevoir la confirmation d'arrivee de l'ascenseur
	 //effacer le message traite correspondant du canal

	do	//traitement des appels a l'ascenseur (de l'exterieur)
			
		:: empty(chCommandeAsc) ->  chAppelAscenseur?< etage , sens >;//copie du premier message du canal
									chCommandeAsc! etage , sens//envoi de l'ordre a l'ascenseur

		:: nempty(chCommandeAsc) -> //attendre la confirmation que l'ascenseur a fini	 
									do
										:: (etage == etageCourantAsc) && (etatPorteAsc == ouverte) -> 
											printf("Ascenseur arrive %e", etage);
											empty(chCommandeAsc);
											chAppelAscenseur??etage , sens //???
											break

									od
	od
}


/* ----------------------------
  Ascenseur 
---------------------------- */

active proctype Ascenseur() {

	mtype:position etage; 
	mtype:sensDepl sens;

	do //simplifier la lecture dans le canal
		::chCommandeAsc?<etage , sens>; etageCourantAsc = etage; etatPorteAsc = ouverte;
	od

};

/* ----------------------------
  Utilisateur
---------------------------- */

proctype Utilisateur( mtype:position etageUtilisateur; mtype:sensDepl sens) {
	
	
	do
		//si l'ascenseur est la, l'utilisateur y entre
		::(etageUtilisateur == etageCourantAsc) && (etatPorteAsc == ouverte) -> break 

		//on appelle l'ascenseur si ne n'est deja fait
		::!(chAppelAscenseur??[etageUtilisateur, sens]) -> chAppelAscenseur!etageUtilisateur, sens; 
													   printf("utilisateur %d appelle %e %e", _pid, etageUtilisateur, sens);
	od

	entrerDansAsc: chDetectionEntree!UTILISATEUR_INTERIEUR_ASCENSEUR;
					printf("utilisateur %d entre %e %e", _pid, etageUtilisateur, sens);
	
};


/*----------------------------------------------------------------------------------------
Initialisations
----------------------------------------------------------------------------------------*/

init{
	run Utilisateur(etage0, monter);
}
