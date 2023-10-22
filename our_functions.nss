#include "NW_I0_GENERIC"
#include "our_constants"

void T2_ShoutClosestEnemyLocation(object oPC) {
	object oClosestEnemy = GetNearestObject(OBJECT_TYPE_CREATURE, oPC, 1);

	if (GetIsObjectValid(oClosestEnemy) && GetIsEnemy(oPC, oClosestEnemy)) {
		string sEnemyName = GetName(oClosestEnemy);
		string sMessage = "The closest enemy is: " + sEnemyName;
		SpeakString(sMessage, TALKVOLUME_SHOUT);
	} else {
		// SpeakString("No enemies nearby.", TALKVOLUME_SHOUT);
	}
}

string T2_GetNotSoRandomTarget(object self) {
	// The next line moves to the spawn location of the similar opponent
	// ActionMoveToLocation( GetLocation( GetObjectByTag( "WP_" + OpponentColor( OBJECT_SELF ) + "_"
	// + IntToString( GetLocalInt( OBJECT_SELF, "INDEX" ) ) ) ), TRUE );

	if (IsWizardLeft(self))
		return WpClosestAltarLeft();
	else if (IsWizardRight(self))
		return WpClosestAltarRight();

	int iTarget = 0;

	if (IsMaster(self))
		iTarget = Random(8);
	else
		iTarget = Random(10);

	if (iTarget < 4)
		return WpDoubler();
	else if (iTarget < 6)
		return WpFurthestAltarLeft();
	else if (iTarget < 8)
		return WpFurthestAltarRight();
	else {
		int iTarget = Random(2);
		if (iTarget == 0)
			return WpClosestAltarLeft();
		else
			return WpClosestAltarRight();
	}
	return "";
}

int T2_DetermineNeedNewTarget(object oTarget, string sTarget, object self) {
	// If there is a member of my own team close to the target and closer than me,
	// and no enemy is closer and this other member is not in combat and
	// has the same target, then choose a new target.
	float fToTarget = GetDistanceToObject(oTarget);
	int i = 1;
	object oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oTarget), i);
	while (GetIsObjectValid(oCreature)) {
		if (GetLocation(oCreature) == GetLocation(self)) break;
		if (GetDistanceBetween(oCreature, oTarget) > fToTarget) break;
		if (GetDistanceBetween(oCreature, oTarget) > 5.0) break;
		if (!SameTeam(oCreature)) break;
		if (GetIsInCombat(oCreature)) break;
		if (GetLocalString(oCreature, "TARGET") == sTarget) {
			return TRUE;
			break;
		}
		++i;
		oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oTarget), i);
	}
	return FALSE;
}

// sets a new target, if needed, and returns the distance to the target
float T2_SetNewTargetIfNeeded(object oTarget, string sTarget, object self) {
	// if the new target is not valid, then choose another new target
	int j = 0;
	while (T2_DetermineNeedNewTarget(oTarget, sTarget, self)) {
		++j;
		sTarget = T2_GetNotSoRandomTarget(self);
		SetLocalString(self, "TARGET", sTarget);
		oTarget = GetObjectByTag(sTarget);
		if (j > 5) break;
	}

	if (j > 0) {
		string sMessage = "Going to: " + sTarget;
		SpeakString(sMessage, TALKVOLUME_SHOUT);
	}

	if (!GetIsObjectValid(oTarget)) return 0.0;
	return GetDistanceToObject(oTarget);
}

void T2_DoHealing() {
	if (TalentHeal()) {
		SpeakString("I am healing.", TALKVOLUME_SHOUT);
		return;
	}
}