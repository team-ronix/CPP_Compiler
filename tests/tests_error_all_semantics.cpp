// tests_error_all_semantics.cpp
// One test case per distinct ERRORF / WARNF site across the compiler.
// Every line that is expected to produce an error / warning is annotated.


int helperOneParam(int x) {
    return x;
}


// ERRORF: "Variable '%s' already declared in this scope."  (DECLARATION branch)
int redecl = 1;
int redecl = 2;


// ERRORF: "Type mismatch for variable '%s'. Expected type %s."
int typeMismatch = "hello";


// ERRORF: "Constant variable '%s' must be initialized."
const int uninitConst;


// ERRORF: "Type mismatch for variable '%s'. Expected type %s."  (CONST branch)
const int constBadType = "oops";


// ERRORF: "Non-default parameter '%s' cannot follow default parameters."
int badParamOrder(int a = 1, int b) {
    return a;
}


// ERRORF: "Function '%s' already declared in this scope."
void dupFunc() {}
void dupFunc() {}


// ERRORF: "Variable '%s' already declared in this scope."  (function name check)
void existingFunc() {}
int existingFunc = 0;


// ERRORF: "Return type mismatch. Expected type %s."
int wrongReturnType() {
    return "oops";
}


// ERRORF: "'return' statement with a value in a void function."
void voidWithReturn() {
    return 1;
}


// WARNF: "Function '%s' may reach end without returning a value."
int mayNotReturn(int x) {
    if (x > 0) {
        return 1;
    }
}

int main() {

    
    // ERRORF: "Argument type mismatch in function '%s' call. Expected type %s"
    int callBadType = helperOneParam("z");

    
    // ERRORF: "Too few arguments in function '%s' call."
    int callTooFew = helperOneParam();

    
    // ERRORF: "Function '%s' called with too many arguments."
    int callTooMany = helperOneParam(1, 2);

    
    // ERRORF: "Function '%s' not declared."
    int callUndef = undefinedFunc(1);

    
    // ERRORF: "Variable '%s' not declared."
    notDeclared = 5;

    
    // WARNF: "Variable '%s' is used before initialization."
    int uninitVar;
    int useUninit = uninitVar + 1;

    
    // ERRORF: "'break' statement not within a loop."
    break;

    
    // ERRORF: "'continue' statement not within a loop."
    continue;

    
    // ERRORF: "Variable '%s' not declared."  (scope out of block)
    {
        int innerVar = 42;
    }
    innerVar = 1;

    
    // ERRORF: "divide or mod by zero error in '%s' operation."
    int divZero = 10 / 0;

    
    // ERRORF: "Modulus operator '%%' not supported for float operands."
    float modFloat = 3.5 % 2.0;

    
    // ERRORF: "Unsupported type %d for left operand in '%s'."
    bool cmpLeftErr = "abc" < 3;

    
    // ERRORF: "Unsupported type %d for right operand in '%s'."
    bool cmpRightErr = 3 < true;

    
    // ERRORF: "Unary 'NOT' operator requires bool/numeric operand."
    bool notErr = !"abc";

    
    // ERRORF: "Left operand of '%s' must be bool/numeric."
    bool andLeftErr = "abc" && 1;

    
    // ERRORF: "Right operand of '%s' must be bool/numeric."
    bool orRightErr = 1 || "abc";

    
    // ERRORF: "Cannot increment constant variable '%s'."
    const int constInc = 5;
    constInc++;

    
    // ERRORF: "Cannot decrement constant variable '%s'."
    const int constDec = 3;
    constDec--;

    
    // WARNF: "Variable '%s' is used before initialization."  (handleCompoundAssign)
    int uninitCompound;
    uninitCompound += 1;

    
    // ERRORF: "Variable '%s' you can't assign value to variable not declared before"
    // (handleCompoundAssign in arithmetic.c)
    neverDeclared += 1;

    
    // ERRORF: "Unsupported type %d for left operand in '%s'."
    // bool is not int/float/char, so arithmetic rejects it on the left side
    int arithBadLeft = true + 1;

    
    // ERRORF: "Unsupported type %d for right operand in '%s'."
    int arithBadRight = 1 + true;

    
    // ERRORF: "Modulus operator '%%' not supported for float operands."
    float modFloatNonZero = 5.5 % 2.5;

    
    // ERRORF: "divide or mod by zero error in '%s' operation."
    int modZero = 7 % 0;

    
    // ERRORF: "Unsupported type %d for left operand in '%s'."
    // string is not int/float/char, so comparison rejects it on the left side
    bool cmpArithLeft = "x" > 1;

    
    // ERRORF: "Unsupported type %d for right operand in '%s'."
    bool cmpArithRight = 1 > "x";

    
    // ERRORF: "Unary 'NOT' operator requires bool/numeric operand."
    bool logicNotString = !"hello";

    
    // ERRORF: "Left operand of 'AND' must be bool/numeric."
    bool logicAndLeft = "hello" && true;

    
    // ERRORF: "Right operand of 'OR' must be bool/numeric."
    bool logicOrRight = true || "hello";

    
    // ERRORF: "Variable '%s' not declared."
    neverDeclaredInc++;

    return 0;
}
