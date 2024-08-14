package;

import peote.view.UniformFloat;

class Param {
    public var label:String;
    public var identifier:String;
    public var valueStart:Float;
    public var valueEnd:Float;
    public var uniform(default, null):UniformFloat;

    public var value(get, set):Float;
    inline function get_value():Float return uniform.value;
    inline function set_value(v:Float):Float return uniform.value = v;

    public function new(label:String, identifier:String, value:Float, valueStart:Float, valueEnd:Float) {
        this.label = label;
        this.identifier = identifier;
        this.valueStart = valueStart;
        this.valueEnd = valueEnd;
        uniform = new UniformFloat(identifier, value);
    }
}

@:structInit
class DefaultParams {
    public var startIndex:Param;
    public var iterPre:Param;
    public var iterMain:Param;
    public var balance:Param;

    public var uniforms(get, never):Array<UniformFloat>;
    inline function get_uniforms():Array<UniformFloat> {
        return [
            startIndex.uniform,
            iterPre.uniform,
            iterMain.uniform,
            balance.uniform,
        ];
    }
}

typedef FormulaParams = Map<String, Param>; 