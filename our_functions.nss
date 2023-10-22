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

void T2_DoHealing() {
	if (TalentHeal()) {
		SpeakString("I am healing.", TALKVOLUME_SHOUT);
		return;
	}
}

string T2_GetTargetAltar(string condition) {
	string c_AL = WpClosestAltarLeft();
	string c_AR = WpClosestAltarRight();
	string f_AL = WpFurthestAltarLeft();
	string f_AR = WpFurthestAltarRight();

	if (ClaimerOf(c_AL) == condition)
		return c_AL;
	else if (ClaimerOf(c_AR) == condition)
		return c_AR;
	else if (ClaimerOf(f_AL) == condition)
		return f_AL;
	else if (ClaimerOf(f_AR) == condition)
		return f_AR;
	else
		return "";
}

string T2_ChooseStrategicAltar(object self) {
	string sMyColor = MyColor(self);
	string sOpponentColor = OpponentColor(self);

	string emptyAltar = T2_GetTargetAltar("");
	if (emptyAltar != "") return emptyAltar;

	string defAltar = T2_GetTargetAltar(sMyColor);
	string attackAltar = T2_GetTargetAltar(sOpponentColor);
	string targetAltar = "";
	string mode = "";

	if (defAltar != "") {
		targetAltar = defAltar;
		mode = "defend";
	} else if (attackAltar != "") {
		targetAltar = attackAltar;
		mode = "attack";
	} else
		return T2_GetNotSoRandomTarget(self);

	object oAltar = GetObjectByTag(targetAltar);
	object oEnemy = GetNearestCreature(1, 1, oAltar, 1, -1, 2, 1);

	if (mode == "defend") {
		// Assuming 5.0 is a reasonable distance to detect threats
		if (GetIsObjectValid(oEnemy) && GetDistanceBetween(oAltar, oEnemy) <= 5.0)
			return targetAltar;
	} else if (mode == "attack") {
		// Assuming 5.0 is a reasonable distance to detect defenders
		if (!GetIsObjectValid(oEnemy) || GetDistanceBetween(oAltar, oEnemy) > 5.0)
			return targetAltar;
	}
	return T2_GetNotSoRandomTarget(self);
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
float T2_SetNewTargetIfNeeded(object oTarget, string sTarget, object self,
							  string method = "random") {
	// if the new target is not valid, then choose another new target
	int j = 0;
	while (T2_DetermineNeedNewTarget(oTarget, sTarget, self)) {
		++j;
		if (method == "random")
			sTarget = T2_GetNotSoRandomTarget(self);
		else if (method == "strategic")
			sTarget = T2_ChooseStrategicAltar(self);

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
