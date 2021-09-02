package tools;

/**
 * ...
 * @author YellowAfterlife
 */
class MathTools {
	public static function roundIfCloseToEps(f:Float):Float {
		var i = Math.fround(f);
		return (Math.abs(f - i) < AseSync.epsilon) ? i : f;
	}
	public static function gcd(u:Int, v:Int) {
		// https://en.wikipedia.org/wiki/Binary_GCD_algorithm
		// Base cases
		//  gcd(n, n) = n
		if (u == v)
			return u;
		
		//  Identity 1: gcd(0, n) = gcd(n, 0) = n
		if (u == 0)
			return v;
		if (v == 0)
			return u;

		if (u % 2 == 0) { // u is even
			if (v % 2 == 1) // v is odd
				return gcd(u>>1, v); // Identity 3
			else // both u and v are even
				return 2 * gcd(u>>1, v>>1); // Identity 2

		} else { // u is odd
			if (v % 2 == 0) // v is even
				return gcd(u, v>>1); // Identity 3

			// Identities 4 and 3 (u and v are odd, so u-v and v-u are known to be even)
			if (u > v)
				return gcd((u - v)>>1, v);
			else
				return gcd((v - u)>>1, u);
		}
	}
}