use linesweeper::FillRule;

pub(crate) fn parse_fill_rule(rule: &str) -> Option<FillRule> {
    match rule {
        "non-zero" => Some(FillRule::NonZero),
        "even-odd" => Some(FillRule::EvenOdd),
        _ => None,
    }
}

pub(crate) fn winding_inside(winding: i32, fill_rule: FillRule) -> bool {
    match fill_rule {
        FillRule::EvenOdd => winding % 2 != 0,
        FillRule::NonZero => winding != 0,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_fill_rule_all_valid() {
        assert!(matches!(
            parse_fill_rule("non-zero"),
            Some(FillRule::NonZero)
        ));
        assert!(matches!(
            parse_fill_rule("even-odd"),
            Some(FillRule::EvenOdd)
        ));
    }

    #[test]
    fn parse_fill_rule_invalid() {
        assert_eq!(parse_fill_rule("evenodd"), None);
        assert_eq!(parse_fill_rule("nonzero"), None);
    }

    #[test]
    fn winding_inside_non_zero() {
        assert!(!winding_inside(0, FillRule::NonZero));
        assert!(winding_inside(1, FillRule::NonZero));
        assert!(winding_inside(-1, FillRule::NonZero));
        assert!(winding_inside(2, FillRule::NonZero));
    }

    #[test]
    fn winding_inside_even_odd() {
        assert!(!winding_inside(0, FillRule::EvenOdd));
        assert!(winding_inside(1, FillRule::EvenOdd));
        assert!(!winding_inside(2, FillRule::EvenOdd));
        assert!(winding_inside(3, FillRule::EvenOdd));
        assert!(!winding_inside(-2, FillRule::EvenOdd));
    }
}
