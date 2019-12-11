#define tpsAttenteMax 50;
mtype = {SIGNAL_PRESENCE, SIGNAL_OUVRIR, SIGNAL_OUVERTES, SIGNAL_FERMER, SIGNAL_FERMEES, SIGNAL_INIT, SIGNAL_TIMEOUT};
int cpt;
chan chPresence = [0] of {mtype};
chan 	chPortes = [1] of {mtype};
chan	chTimer = [0] of {mtype}; /*S'il y a un Timer*/
bit ok_systeme, ok_individu;


active proctype Systeme() {
	PortesFermees: 	chPresence?SIGNAL_PRESENCE; chPortes!SIGNAL_OUVRIR; chPortes?[SIGNAL_OUVERTES]; ok_systeme=1;
									chTimer!SIGNAL_INIT;/*S'il y a un Timer*/ 
	PortesOuvertes:	do
			:: chPresence?SIGNAL_PRESENCE -> chTimer!SIGNAL_INIT; 
			:: chTimer?SIGNAL_TIMEOUT -> chPortes!SIGNAL_FERMER; chPortes?SIGNAL_FERMEES; goto PortesFermees /*S'il y a un Timer*/
			od
}

active[10] proctype Individu() {
	printf("Je suis Individu_%d, je veux entrer !", _pid);
	chPresence!SIGNAL_PRESENCE;
	do
	:: chPortes?[SIGNAL_OUVERTES] -> ok_individu=1; printf("J'entre, merci."); break
	:: else -> printf("J'attends ...")
	od
}

active proctype Portes() {
	Fermees: 	chPortes?SIGNAL_OUVRIR; printf("Les portes s'ouvrent ..."); chPortes!SIGNAL_OUVERTES;
	Ouvertes:	chPortes?SIGNAL_FERMER; printf("Les portes se ferment ..."); chPortes!SIGNAL_FERMEES; goto Fermees;
}

/*S'il y a un Timer*/
active proctype Timer()  {
	Off: 	chTimer?SIGNAL_INIT; printf("J'initialise le compteur ..."); cpt = 0;
	On:	do
		:: chTimer?SIGNAL_INIT; printf("Je reinitialise le compteur ..."); cpt = 0
		:: cpt == tpsAttenteMax -> chTimer!SIGNAL_TIMEOUT; 
		if 
	    ::ok_systeme==1 && ok_individu==1 -> chPortes?SIGNAL_OUVERTES; ok_systeme=0; ok_individu=0;
	    fi;
	    goto Off
		:: cpt < tpsAttenteMax -> cpt = cpt +1
		od
}
