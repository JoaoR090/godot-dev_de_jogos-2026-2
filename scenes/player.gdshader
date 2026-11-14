shader_type spatial;

uniform sampler2D textura_nuvem : repeat_enable;

void fragment() {
	vec3 posicao_mundo = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// CAMADA 1: O movimento principal que você já tinha
	vec2 uv_nuvem1 = posicao_mundo.xz * 0.05; 
	uv_nuvem1.x += TIME * 0.02;
	uv_nuvem1.y += TIME * 0.01;
	
	// CAMADA 2: Uma escala diferente, movendo mais devagar e em outra direção
	vec2 uv_nuvem2 = posicao_mundo.xz * 0.001; 
	uv_nuvem2.x -= TIME * 0.001;
	uv_nuvem2.y += TIME * 0.0005;
	
	// Lê o preto e branco das duas posições diferentes
	float densidade1 = texture(textura_nuvem, uv_nuvem1).r;
	float densidade2 = texture(textura_nuvem, uv_nuvem2).r;
	
	// Multiplica as duas. Isso faz as nuvens "nascerem e morrerem" organicamente
	// O * 1.8 serve para compensar a perda de brilho da multiplicação
	float densidade_final = (densidade1 * densidade2) * 1.8;
	
	ALPHA = densidade_final;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}