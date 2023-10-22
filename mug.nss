#include "NW_I0_GENERIC"
#include "our_constants"

void T4_DetermineCombatRound(object oIntruder = OBJECT_INVALID, int nAI_Difficulty = 10) {
	DetermineCombatRound(oIntruder, nAI_Difficulty);
}

string T4_GetNotSoRandomTarget() { return "SomeTargetTag"; }

void T4_HeartBeat() {
	if (GetIsInCombat()) return;

	string sTarget = GetLocalString(OBJECT_SELF, "TARGET");
	if (sTarget == "") {
		SpeakString("st1", TALKVOLUME_SHOUT );
		eturn;
	

	bject oTarget = GetObjectByTag( Target ;
	f (!GetIsObjectValid( Target ) 
		peakString( sT4", TALKVOLUME_SHOUT );

		turn;

	

	 (nAI_Difficulty >= 7)
 

		plyBuffs(OBJECT_SELF);

	


	oat fToTarget = GetDistanceToObject( oarget )

	t i = 1;

	t bNewTarget = FALSE;

	ject oCreature = GetNearestObjectToLocation( OJECT_TYPE_CREATURE, GetLocation( oarget ) i )

	ile (GetIsObjectValid( oreature )
 

		 (GetLocation( oreature )== GetLocation( OJECT_SELF )
 eak;

		 (GetDistanceBetween( oreature, oTarget )> fToTarget)
 eak;

		 (GetDistanceBetween( oreature, oTarget )> 5.0)
 eak;

		 (!SameTeam( oreature )
 eak;

		 (GetIsInCombat( oreature )
 eak;

		 (GetLocalString( oreature, "TARGET" )== sTarget)
 

			ewTarget = TRUE;

			eak;

		

		i;

		reature = GetNearestObjectToLocation( OJECT_TYPE_CREATURE, GetLocation( oarget ) i )

	


	 (bNewTarget)
 

		arget = T4_GetNotSoRandomTarget();

		tLocalString( OJECT_SELF, "TARGET", sTarget )

		arget = GetObjectByTag( sarget )

		 (!GetIsObjectValid( oarget )
 

			eakString( "t3", TALKVOLUME_SHOUT );
 
			urn;
 
		 
		Target = GetDistanceToObject( oTrget );
 
	

	(fToTarget > 0.5)
  ionMoveToLocation( GeLocation( oTrget ),TRUE );


	urn;
}


d T4_Spawn()
{  
	ing sTarget = T4_GetNotSoRandomTarget();
 
	LocalString(OBJECT_SELF, "TARGET", sTarget);


	ionMoveToLocation(GetLocation(GetObjectByTag(sTarget)), TRUE);
}

void T4_UserDefined( in Event ){  
	tch (Event)
   
		e EVENT_ATTACKED:
 
			ak;


		e EVENT_DAMAGED:
 
			ak;


		e EVENT_END_COMBAT_ROUND:
 
			ak;


		e EVENT_HEARTBEAT:
 
			HeartBeat();
 
			ak;


		e EVENT_PERCEIVE:
 
			ak;


		e EVENT_SPELL_CAST_AT:
 
			ak;


		e EVENT_DISTURBED:
 
			ak;


		e EVENT_DEATH:
 
			ak;


		e EVENT_SPAWN:
 
			Spawn();
 
			ak;
 
	

	urn;
}

void T4_Initialize( sting sColor ){   TeamName( sClor, "Default-" + GetStringLowerCase( sClor ) ;
} 