#include "utils.h"
#include <stdio.h>

canConvertResult canConvert(valType from, valType to) {
    canConvertResult res;
    res.canConvert = false;

    if (from == to) {
        res.canConvert = true;
        return res;
    }

    switch (from) {
        case typeInt:
            res.canConvert = (to == typeFloat || to == typeBool || to == typeChar);
            break;
        case typeFloat:
            res.canConvert = (to == typeInt || to == typeBool);
            break;
        case typeChar:
            res.canConvert = (to == typeInt || to == typeFloat || to == typeBool);
            break;
        case typeBool:
            res.canConvert = (to == typeInt || to == typeFloat);
            break;
        default:
            res.canConvert = false;
            break;
    }

    return res;
}

valNode convertValue(valNode val, valType targetType) {
    valNode result;
    result.type = targetType;

    switch (targetType) {
        case typeInt:
            if (val.type == typeFloat)
                result.value.iValue = (int)val.value.fValue;
            else if (val.type == typeChar)
                result.value.iValue = (int)val.value.cValue;
            else if (val.type == typeBool)
                result.value.iValue = val.value.bValue ? 1 : 0;
            else
                result.value.iValue = val.value.iValue;
            break;

        case typeFloat:
            if (val.type == typeInt)
                result.value.fValue = (float)val.value.iValue;
            else if (val.type == typeChar)
                result.value.fValue = (float)(int)val.value.cValue;
            else if (val.type == typeBool)
                result.value.fValue = val.value.bValue ? 1.0f : 0.0f;
            else
                result.value.fValue = val.value.fValue;
            break;

        case typeBool:
            if (val.type == typeInt)
                result.value.bValue = (val.value.iValue != 0);
            else if (val.type == typeFloat)
                result.value.bValue = (val.value.fValue != 0.0f);
            else if (val.type == typeChar)
                result.value.bValue = (val.value.cValue != '\0');
            else
                result.value.bValue = val.value.bValue;
            break;

        case typeChar:
            if (val.type == typeInt)
                result.value.cValue = (char)val.value.iValue;
            else
                result.value.cValue = val.value.cValue;
            break;

        default:
            fprintf(stderr, "Error: Cannot convert to target type %d.\n", targetType);
            result = val;
            break;
    }

    return result;
}
