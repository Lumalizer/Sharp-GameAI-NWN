#include "NW_I0_GENERIC"
#include "our_constants"
#include "our_functions"

void T4_DetermineCombatRound(object oIntruder = OBJECT_INVALID, int nAI_Difficulty = 10) {
	DetermineCombatRound(oIntruder, nAI_Difficulty);
}

void ApplyBuffs(object oNPC) {}

void T4_HeartBeat() {
	if (GetIsInCombat()) return;

	string sTarget = GetLocalString(OBJECT_SELF, "TARGET");
	if (sTarget == "") {
		SpeakString("st1", TALKVOLUME_SHOUT);
		return;
	}

	object oTarget = GetObjectByTag(sTarget);
	if (!GetIsObjectValid(oTarget)) {
		SpeakString("sT4", TALKVOLUME_SHOUT);
		return;
	}

	// if (nAI_Difficulty >= 7) {
	// 	ApplyBuffs(OBJECT_SELF);
	// }

	float fToTarget = GetDistanceToObject(oTarget);
	int i = 1;
	int bNewTarget = FALSE;
	object oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oTarget), i);
	while (GetIsObjectValid(oCreature)) {
		if (GetLocation(oCreature) == GetLocation(OBJECT_SELF)) break;
		if (GetDistanceBetween(oCreature, oTarget) > fToTarget) break;
		if (GetDistanceBetween(oCreature, oTarget) > 5.0) break;
		if (!SameTeam(oCreature)) break;
		if (GetIsInCombat(oCreature)) break;
		if (GetLocalString(oCreature, "TARGET") == sTarget) {
			bNewTarget = TRUE;
			break;
		}
		++i;
		oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oTarget), i);
	}

	if (bNewTarget) {
		sTarget = T2_GetNotSoRandomTarget(OBJECT_SELF);
		SetLocalString(OBJECT_SELF, "TARGET", sTarget);
		oTarget = GetObjectByTag(sTarget);
		if (!GetIsObjectValid(oTarget)) {
			SpeakString("st3", TALKVOLUME_SHOUT);
			return;
		}
		fToTarget = GetDistanceToObject(oTarget);
	}

	if (fToTarget > 0.5) ActionMoveToLocation(GetLocation(oTarget), TRUE);

	return;
}

void T4_Spawn() {
	string sTarget = T2_GetNotSoRandomTarget(OBJECT_SELF);
	SetLocalString(OBJECT_SELF, "TARGET", sTarget);

	ActionMoveToLocation(GetLocation(GetObjectByTag(sTarget)), TRUE);
}

void T4_UserDefined(int Event) {
	switch (Event) {
		case EVENT_ATTACKED:
			break;

		case EVENT_DAMAGED:
			break;

		case EVENT_END_COMBAT_ROUND:
			break;

		case EVENT_HEARTBEAT:
			T4_HeartBeat();
			break;

		case EVENT_PERCEIVE:
			break;

		case EVENT_SPELL_CAST_AT:
			break;

		case EVENT_DISTURBED:
			break;

		case EVENT_DEATH:
			break;

		case EVENT_SPAWN:
			T4_Spawn();
			break;
	}

	return;
}

void T4_Initialize(string sColor) { SetTeamName(sColor, "Default-" + GetStringLowerCase(sColor)); }