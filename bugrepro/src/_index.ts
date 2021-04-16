import * as argon2 from "argon2"

import RE2 from "re2"



console.log( `\n\nTEST ARGON2 WORKING` );
let kdfHash = await argon2.hash( "hello" );
console.log( `kdfHash= ${ kdfHash }` );


console.log( `\n\nTEST RE2 WORKING` );
const re = new RE2( "a(b*)" );
var result = re.exec( "abbc" );
console.log( result[ 0 ] ); // "abb"
console.log( result[ 1 ] ); // "bb"

