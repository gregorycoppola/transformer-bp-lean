import Lake
open Lake DSL
package «transformer-bp-lean» where
  name := `transformerBPLean
lean_lib «TransformerBPLean» where
  roots := #[`TransformerBPLean]