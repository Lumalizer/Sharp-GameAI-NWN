#include "NW_I0_GENERIC"
#include "our_constants"

void ShoutClosestEnemyLocation(object oPC) {
	object oClosestEnemy = GetNearestObject(OBJECT_TYPE_CREATURE, oPC, 1);

	if (GetIsObjectValid(oClosestEnemy) && GetIsEnemy(oPC, oClosestEnemy)) {
		string sEnemyName = GetName(oClosestEnemy);
		string sMessage = "The closest enemy is: " + sEnemyName;
		SpeakString(sMessage, TALKVOLUME_SHOUT);
	} else {
		// SpeakString("No enemies nearby.", TALKVOLUME_SHOUT);
	}
}

float GetCreatureThreatLevel(object oCreature, object self) {
	int isFriendly = SameTeam(oCreature, self);
	int inCombat = GetIsInCombat(oCreature);
	int isMaster = IsMaster(oCreature);
	int isFighter = IsFighter(oCreature);
	int isCleric = IsCleric(oCreature);
	int isWizard = IsWizard(oCreature);

	float fThreat = 1 * isCleric + 1.1 * isWizard + 1.4 * isFighter + 1.7 * isMaster;
	if (isFriendly) fThreat *= -1.0;
	if (inCombat) fThreat *= 1.2;
	if (!isFriendly && inCombat) fThreat += 0.1;
	int health = GetHealth(oCreature);
	fThreat = fThreat * ((health + 1) / 6.0);

	return fThreat;
}

float GetLocationThreatLevel(string loc, object self) {
	object oLocation = GetObjectByTag(loc);
	float fThreatLevel = 0.0;

	// check all creatures in the area
	int i = 1;
	object oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oLocation), i);
	while (GetIsObjectValid(oCreature)) {
		float fDistance = GetDistanceBetween(oCreature, oLocation);
		if (fDistance > 30.0) break;
		fThreatLevel += GetCreatureThreatLevel(oCreature, self);
		++i;
		if (i > 12) break;
		oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oLocation), i);
	}

	return fThreatLevel;
}

string GetNotSoRandomTarget(object self) {
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

void DoHealing() {
	if (TalentHealingSelf()) {
		SpeakString("I am healing myself.", TALKVOLUME_SHOUT);
		return;
	}
	if (TalentHeal()) {
		SpeakString("I am healing.", TALKVOLUME_SHOUT);
		return;
	}
}

string GetSmartAltar(object self) {
	string sMyColor = MyColor(self);
	string sOpponentColor = OpponentColor(self);
	float ourThreat = GetCreatureThreatLevel(self, self);

	int isMaster = IsMaster(self);
	int isFighter = IsFighter(self);
	int isCleric = IsCleric(self);
	int isWizard = IsWizard(self);

	string c_AL = WpClosestAltarLeft();
	string c_AR = WpClosestAltarRight();
	string f_AL = WpFurthestAltarLeft();
	string f_AR = WpFurthestAltarRight();
	string d = WpDoubler();

	string claimerC_AL = ClaimerOf(c_AL);
	string claimerC_AR = ClaimerOf(c_AR);
	string claimerF_AL = ClaimerOf(f_AL);
	string claimerF_AR = ClaimerOf(f_AR);
	string claimerD = ClaimerOf(d);

	float distanceC_AL = GetDistanceBetween(self, GetObjectByTag(c_AL));
	float distanceC_AR = GetDistanceBetween(self, GetObjectByTag(c_AR));
	float distanceF_AL = GetDistanceBetween(self, GetObjectByTag(f_AL));
	float distanceF_AR = GetDistanceBetween(self, GetObjectByTag(f_AR));
	float distanceD = GetDistanceBetween(self, GetObjectByTag(d));

	float fThreat_c_AL = GetLocationThreatLevel(c_AL, self);
	float fThreat_c_AR = GetLocationThreatLevel(c_AR, self);
	float fThreat_f_AL = GetLocationThreatLevel(f_AL, self);
	float fThreat_f_AR = GetLocationThreatLevel(f_AR, self);
	float fThreat_d = GetLocationThreatLevel(d, self);

	string target = "";
	string targetReason = "";

	// class-specific behavior
	if (isWizard) {
		if (distanceC_AL < distanceC_AR && claimerC_AL != sMyColor)
			target = c_AL;
		else if (claimerC_AR != sMyColor)
			target = c_AR;
		else if (claimerC_AL != sMyColor)
			target = c_AL;

		if (target != "") targetReason = "Wizard Target: ";

	} else if (isMaster) {
		if (claimerD == sOpponentColor) target = d;
		if (target != "") targetReason = "Master Target: ";
	}

	// control close unclaimed altars
	if (target == "") {
		if (claimerD == "" && distanceD < 20.0)
			target = d;
		else if (claimerC_AL == "" && distanceC_AL < 20.0)
			target = c_AL;
		else if (claimerC_AR == "" && distanceC_AR < 20.0)
			target = c_AR;
		else if (claimerF_AL == "" && distanceF_AL < 20.0)
			target = f_AL;
		else if (claimerF_AR == "" && distanceF_AR < 20.0)
			target = f_AR;

		if (target != "") targetReason = "Unclaimed Target (close): ";
	}

	// threat level based decisions
	if (target == "") {
		int threat_decision_d = (fThreat_d >= 0.0 && fThreat_d + ourThreat < 1.3);
		int threat_decision_c_AL = (fThreat_c_AL > 0.0 && fThreat_c_AL + ourThreat < 0.4);
		int threat_decision_c_AR = (fThreat_c_AR > 0.0 && fThreat_c_AR + ourThreat < 0.4);
		int threat_decision_f_AL = (fThreat_f_AL > 0.0 && fThreat_f_AL + ourThreat < 0.3);
		int threat_decision_f_AR = (fThreat_f_AR > 0.0 && fThreat_f_AR + ourThreat < 0.3);

		if (threat_decision_d)
			target = d;
		else if (threat_decision_c_AL && threat_decision_c_AR) {
			if (distanceC_AL < distanceC_AR)
				target = c_AL;
			else
				target = c_AR;
		} else if (threat_decision_c_AL)
			target = c_AL;
		else if (threat_decision_c_AR)
			target = c_AR;
		else if (threat_decision_f_AL && threat_decision_f_AR) {
			if (distanceF_AL < distanceF_AR)
				target = f_AL;
			else
				target = f_AR;
		} else if (threat_decision_f_AL)
			target = f_AL;
		else if (threat_decision_f_AR)
			target = f_AR;

		if (target != "") targetReason = "Threat Target: ";
	}

	// control unclaimed altars
	if (target == "") {
		if (claimerD == "" && distanceD < 20.0)
			target = d;
		else if (claimerC_AL == "" && distanceC_AL < 20.0)
			target = c_AL;
		else if (claimerC_AR == "" && distanceC_AR < 20.0)
			target = c_AR;
		else if (claimerF_AL == "" && distanceF_AL < 20.0)
			target = f_AL;
		else if (claimerF_AR == "" && distanceF_AR < 20.0)
			target = f_AR;
		else if (claimerD == "" && distanceD < 35.0)
			target = d;
		else if (claimerC_AL == "" && distanceC_AL < 35.0)
			target = c_AL;
		else if (claimerC_AR == "" && distanceC_AR < 35.0)
			target = c_AR;
		else if (claimerF_AL == "" && distanceF_AL < 35.0)
			target = f_AL;
		else if (claimerF_AR == "" && distanceF_AR < 35.0)
			target = f_AR;
		else if (claimerD == "" && distanceD < 65.0)
			target = d;
		else if (claimerC_AL == "" && distanceC_AL < 65.0)
			target = c_AL;
		else if (claimerC_AR == "" && distanceC_AR < 65.0)
			target = c_AR;
		else if (claimerF_AL == "" && distanceF_AL < 65.0)
			target = f_AL;
		else if (claimerF_AR == "" && distanceF_AR < 65.0)
			target = f_AR;

		if (target != "") targetReason = "Unclaimed Target: ";
	}

	// random target if all else fails
	if (target == "") {
		target = GetNotSoRandomTarget(self);
		targetReason = "Random Target: ";
	}

	float locationThreat = GetLocationThreatLevel(target, self);
	float locationDistance = GetDistanceBetween(self, GetObjectByTag(target));
	string sMessage = targetReason + target + " Threat score:" + FloatToString(locationThreat) +
					  " Distance:" + FloatToString(locationDistance);
	SpeakString(sMessage, TALKVOLUME_SHOUT);

	return target;
}

string GetTargetAltar(string condition) {
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

string ChooseStrategicAltar(object self) {
	string sMyColor = MyColor(self);
	string sOpponentColor = OpponentColor(self);

	string emptyAltar = GetTargetAltar("");
	if (emptyAltar != "") return emptyAltar;

	string defAltar = GetTargetAltar(sMyColor);
	string attackAltar = GetTargetAltar(sOpponentColor);
	string targetAltar = "";
	string mode = "";

	if (defAltar != "") {
		targetAltar = defAltar;
		mode = "defend";
	} else if (attackAltar != "") {
		targetAltar = attackAltar;
		mode = "attack";
	} else
		return GetNotSoRandomTarget(self);

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
	return GetNotSoRandomTarget(self);
}

int DetermineNeedNewTarget(string sTarget, object self) {
	object oTarget = GetObjectByTag(sTarget);
	object oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oTarget));
	float fToTarget = GetDistanceToObject(oTarget);
	int underOurControl = ClaimerOf(sTarget) == MyColor(self);

	// if I am the closest to the target, then do not choose a new target
	if (oCreature == self) return FALSE;

	// // if target threat is low, then choose a new target
	// if (!GetIsInCombat(oCreature) && GetLocationThreatLevel(sTarget, self) < -2.0) {
	// 	if (Random(2) == 0) {
	// 		SpeakString("Changing target (high allied strength): " + sTarget, TALKVOLUME_SHOUT);
	// 		return TRUE;
	// 	}
	// };

	// if enemy strength is too high, then choose a new target
	if (GetLocationThreatLevel(sTarget, self) > 2.5) {
		SpeakString("Changing target (high enemy strength): " + sTarget, TALKVOLUME_SHOUT);
		return TRUE;
	};

	// If there is a member of my own team close to the target and closer than me,
	// and no enemy is closer and this other member is not in combat and
	// has the same target, then choose a new target.
	int i = 1;
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
string SetNewTargetIfNeeded(string sTarget, object self, string method = "random") {
	// if the new target is not valid, then choose a new target
	if (DetermineNeedNewTarget(sTarget, self)) {
		if (method == "random")
			sTarget = GetNotSoRandomTarget(self);
		else if (method == "strategic")
			sTarget = ChooseStrategicAltar(self);
		else if (method == "smart")
			sTarget = GetSmartAltar(self);

		SetLocalString(self, "TARGET", sTarget);

		if (method != "smart") {
			float locationThreat = GetLocationThreatLevel(sTarget, self);
			string sMessage =
				"Going to: " + sTarget + " Threat score:" + FloatToString(locationThreat);
			SpeakString(sMessage, TALKVOLUME_SHOUT);
		}
	}

	return sTarget;
}
