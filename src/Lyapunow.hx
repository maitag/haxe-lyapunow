package;

import peote.view.*;
import Formula;

import Param.DefaultParams;
import Param.FormulaParams;

import peote.view.Color;

class Lyapunow implements Element
{
	// position in pixel (relative to upper left corner of Display)
	@posX @const public var x:Int = 0;
	@posY @const public var y:Int = 0;
	
	// size in pixel
	@sizeX @varying @const @formula("uResolution.x") var w:Int;
	@sizeY @varying @const @formula("uResolution.y") var h:Int;

	@color var posColor:Color = 0xff0000ff;
	@color var midColor:Color = 0x000000ff;
	@color var negColor:Color = 0x0000ffff;
	// --------------------------------------------------------------------------	
	
	static public var buffer:Buffer<Lyapunow>;
	static public var program:Program;
	static public var element:Lyapunow;
	
	static public function init(display:Display, formula:Formula, sequence:Array<String>,
		positionX:UniformFloat, positionY:UniformFloat, scaleX:UniformFloat, scaleY:UniformFloat, 
		defaultParams:DefaultParams, formulaParams:FormulaParams)
	{	
		buffer = new Buffer<Lyapunow>(1);
		program = new Program(buffer);
		
		program.setColorFormula( 'lyapunow(posColor, midColor, negColor)', false );
		program.setFragmentFloatPrecision("high", false);
		updateShader(formula, sequence, positionX, positionY, scaleX, scaleY, defaultParams, formulaParams);
		
		display.addProgram(program);

		element = new Lyapunow();
        buffer.addElement( element );
	}

	static public function updatePosColor(color:Color) {
		element.posColor = color;
		buffer.updateElement(element);
	}

	static public function updateMidColor(color:Color) {
		element.midColor = color;
		buffer.updateElement(element);
	}

	static public function updateNegColor(color:Color) {
		element.negColor = color;
		buffer.updateElement(element);
	}

	static public function updateShader(formula:Formula, sequence:Array<String>,
		positionX:UniformFloat, positionY:UniformFloat, scaleX:UniformFloat, scaleY:UniformFloat, 
		defaultParams:DefaultParams, formulaParams:FormulaParams) {

		// trace("formula", formula.toString("glsl"));

		// var derivate:Formula = formula.derivate("i").simplify(); // could take to long
		var derivate:Formula = formula.derivate("i");


		// trace("derivate", derivate.toString("glsl"));

		var pre_sequence:String = "";
		var main_sequence:String = "";

		var extra_param:String = "";
		var extra_func_param:String = "";

		if (formula.hasParam("x")) {extra_func_param += ",float x"; extra_param += ",xy.x";}
		if (formula.hasParam("y")) {extra_func_param += ",float y"; extra_param += ",xy.y";}

		for (s in sequence) {
			var p:String = (s == "x" || s == "y") ? "xy."+s : "uParam"+s;
			p += extra_param;
			pre_sequence += 'i = func(i, $p);';
			main_sequence +='i = func(i, $p); index += (log(abs(deriv(i, $p)))*uBalance + deriv(i, $p)*(1.0-uBalance)) / 2.0;';
		}

		program.injectIntoFragmentShader(
			'
				float func(float i, float n $extra_func_param) {
					return ${formula.toString("glsl")};
				}
	
				float deriv(float i, float n $extra_func_param) {
					return ${derivate.toString("glsl")};
				}
	
				void pre_step(inout float i, vec2 xy) {
					$pre_sequence
				}
	
				void main_step(inout float index, inout float i, vec2 xy) {
					$main_sequence
				}
	
				vec4 lyapunow(vec4 posColor, vec4 midColor, vec4 negColor)
				{		
					float i = uStartIndex;

					vec2 xy = ( (vTexCoord*vSize - vec2(uPositionX, uPositionY))/400.0 ) / vec2(uScaleX, uScaleY);
					
					int iter_pre =  int(floor(uIterPre));
					int iter_main = int(floor(uIterMain));
					float iter_main_full = floor(uIterMain) * ${sequence.length}.0;
					if (iter_main_full == 0.0) iter_main_full = 1.175494351e-38;
	
					float nabla_pre = uIterPre - float(iter_pre);
					float nabla_main = uIterMain - float(iter_main);
					
					float index = 0.0;
					
					// pre-iteration ##########################
					
					for (int iter = 0; iter < 21; iter++) {
						if (iter < iter_pre)
						{
							pre_step(i, xy);
						}
					}
					if (nabla_pre != 0.0) {
						float x_pre = i;
						pre_step(i, xy);
						i = i*nabla_pre + x_pre*(1.0-nabla_pre);
					}
						
					// main-iteration ########################
					
					for (int iter = 0; iter < 201; iter++) {
						if (iter < iter_main)
						{
							main_step(index, i, xy);
						}
					}
					
					if (nabla_main == 0.0) {
						index = index/iter_main_full;
					}
					else {
						float index_pre = index/iter_main_full;
	
						main_step(index, i, xy);
	
						index = index/(iter_main_full + ${sequence.length}.0);
						index = index*nabla_main + index_pre*(1.0-nabla_main);
					}
	
					return  index*( (index > 0.0) ? posColor - midColor : midColor - negColor  ) + midColor ;
				}			
			'
			, false // inject uTime
			, defaultParams.uniforms.concat( [for (v in formulaParams) v.uniform] ).concat([positionX, positionY, scaleX, scaleY])
			);
	
	}
	
}