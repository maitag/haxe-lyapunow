package;

import haxe.ds.StringMap;
import peote.view.Uniform;

class Param {
	public var label:String;
	public var identifier:String;
	public var valueStart:Float;
	public var valueEnd:Float;
	public var minStart:Null<Float>;
	public var maxEnd:Null<Float>;
	public var uniform(default, null):UniformFloat;

	public var value(get, set):Float;
	inline function get_value():Float return uniform.value;
	inline function set_value(v:Float):Float return uniform.value = v;

	public function new(label:String, identifier:String, value:Float, valueStart:Float, valueEnd:Float, ?minStart:Null<Float>, ?maxStart:Null<Float>) {
		this.label = label;
		this.identifier = identifier;
		this.valueStart = valueStart;
		this.valueEnd = valueEnd;
		this.minStart = minStart;
		this.maxEnd = maxStart;
		uniform = new UniformFloat(value);
	}
}

@:structInit
class DefaultParams {
	public var startIndex:Param;
	public var iterPre:Param;
	public var iterMain:Param;
	public var balance:Param;

	public var uniforms(get, never):StringMap<Uniform>;
	inline function get_uniforms():StringMap<Uniform> {
		return [
			"uStartIndex" => startIndex.uniform,
			"uIterPre" => iterPre.uniform,
			"uIterMain" => iterMain.uniform,
			"uBalance" => balance.uniform,
		];
	}
}

typedef FormulaParams = Map<String, Param>; 