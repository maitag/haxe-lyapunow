package;

import peote.view.*;
import Param.DefaultParams;

class Lyapunow implements Element
{
	// position in pixel (relative to upper left corner of Display)
	@posX @const public var x:Int = 0;
	@posY @const public var y:Int = 0;
	
	// size in pixel
	@sizeX @varying @const @formula("uResolution.x") var w:Int;
	@sizeY @varying @const @formula("uResolution.y") var h:Int;

	
	// --------------------------------------------------------------------------	
	
	static public var buffer:Buffer<Lyapunow>;
	static public var program:Program;	
	
	static public function init(display:Display, defaultParams:DefaultParams)
	{	
		buffer = new Buffer<Lyapunow>(1);
		program = new Program(buffer);
		
		program.injectIntoFragmentShader(
		"
			float func(float i, float n)
			{
				return 2.5*sin(i+n)*sin(i+n)+2.0;
				// return uParama*sin(i+n)*sin(i+n)+uParamb;

				// return #FORMULA;
			}

			float deriv(float i, float n)
			{
				return 2.5*sin(2.0*(i+n));
				// return uParama*sin(2.0*(i+n));

				// return #DERIVATE;
			}

			void pre_step(inout float i, vec2 xy)
			{
				i = func(i,xy.x);
				i = func(i,xy.y);

				// #PRE_SQEUENCE_CALLS
			}

			void main_step(inout float index, inout float i, vec2 xy)
			{
				i = func(i,xy.x);
				index += (  log(abs(deriv(i,xy.x)))*uBalance + deriv(i,xy.x)*(1.0-uBalance)  ) / 2.0;

				i = func(i,xy.y);
				index += (  log(abs(deriv(i,xy.y)))*uBalance + deriv(i,xy.y)*(1.0-uBalance)  ) / 2.0;
				
				// #PRE_SQEUENCE_CALLS
			}

			vec4 lyapunow()
			{
				vec2 uPosition = vec2(0.0, 0.0);
				vec2 uScale = vec2(800.0/vSize.x, 800.0/vSize.y);
				
				vec3 uColpos = vec3(1.0, 0.0, 0.0);
				vec3 uColmid = vec3(0.0, 0.0, 0.0);
				vec3 uColneg = vec3(0.0, 0.0, 1.0);


				// Parameter
				float i = uStartIndex;
				vec2 xy = (vTexCoord - uPosition) / uScale;
				
				int iter_pre =  int(floor(uIterPre));
				int iter_main = int(floor(uIterMain));
				float iter_main_full = floor(uIterMain) * 2.0; // todo, the 2.0 is generated in depend of how long the sequence is !
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

					index = index/(iter_main_full + 2.0); // todo, the 2.0 is generated in depend of how long the sequence is !
					index = index*nabla_main + index_pre*(1.0-nabla_main);
				}

				return vec4( index*( (index > 0.0) ? uColpos-uColmid : uColmid-uColneg   )+uColmid, 1.0 );
			}			
		"
		, false // inject uTime
		, defaultParams.uniforms
		);
		
		program.setColorFormula( 'lyapunow()' );
		display.addProgram(program);


        buffer.addElement( new Lyapunow() );
	}
	
}