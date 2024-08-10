package;

import peote.view.*;

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
	
	static public function init(display:Display, uniformFloats:Array<UniformFloat>)
	{	
		buffer = new Buffer<Lyapunow>(1);
		program = new Program(buffer);
		
		program.injectIntoFragmentShader(
		"
			float func(float i, float n, float a, float b)
			{
				return a*sin(i+n)*sin(i+n)+b;
				// return #FORMULA;
			}

			float deriv(float i, float n, float a, float b)
			{
				return a*sin(2.0*(i+n));
				// return #DERIVATE;
			}

			void pre_step(inout float i, vec2 xy, float p1, float p2)
			{
				i = func(i,xy.x,p1,p2);
				i = func(i,xy.y,p1,p2);
			}

			void main_step(inout float index, inout float i, vec2 xy, float p1, float p2, float balance)
			{
				i = func(i,xy.x,p1,p2);
				index += (  log(abs(deriv(i,xy.x,p1,p2)))*balance + deriv(i,xy.x,p1,p2)*(1.0-balance)  ) / 2.0;
				i = func(i,xy.y,p1,p2);
				index += (  log(abs(deriv(i,xy.y,p1,p2)))*balance + deriv(i,xy.y,p1,p2)*(1.0-balance)  ) / 2.0;
				// iter = iter + 2;
			}

			vec4 lyapunow()
			{
				float uStart = 0.0;
				vec2 uPosition = vec2(0.0, 0.0);
				vec2 uScale = vec2(800.0/vSize.x, 800.0/vSize.y);
				vec2 uParam = vec2(2.5, 2.0);
				float uIterPre = 0.0;
				float uBalance = 0.5;
				vec3 uColpos = vec3(1.0, 0.0, 0.0);
				vec3 uColmid = vec3(0.0, 0.0, 0.0);
				vec3 uColneg = vec3(0.0, 0.0, 1.0);


				// Parameter
				float i = uStart;
				vec2 xy = (vTexCoord - uPosition) / uScale;
				float p1 = uParam.x;
				float p2 = uParam.y;
				
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
						pre_step(i, xy, p1, p2);
					}
				}
				if (nabla_pre != 0.0) {
					float x_pre = i;
					pre_step(i, xy, p1, p2);
					i = i*nabla_pre + x_pre*(1.0-nabla_pre);
				}
					
				// main-iteration ########################
				
				for (int iter = 0; iter < 201; iter++) {
					if (iter < iter_main)
					{
						main_step(index, i, xy, p1, p2, uBalance);
					}
				}
				
				if (nabla_main == 0.0) {
					index = index/iter_main_full;
				}
				else {
					float index_pre = index/iter_main_full;

					main_step(index, i, xy, p1, p2, uBalance);

					index = index/(iter_main_full + 2.0); // todo, the 2.0 is generated in depend of how long the sequence is !
					index = index*nabla_main + index_pre*(1.0-nabla_main);
				}

				return vec4( index*( (index > 0.0) ? uColpos-uColmid : uColmid-uColneg   )+uColmid, 1.0 );
			}			
		"
		, false // inject uTime
		, uniformFloats
		);
		
		program.setColorFormula( 'lyapunow()' );
		display.addProgram(program);


        buffer.addElement( new Lyapunow() );
	}
	
}