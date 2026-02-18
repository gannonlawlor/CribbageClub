use std::f64::consts::PI;

const TAU: f64 = 0.5;
const CONVERGENCE_TOLERANCE: f64 = 0.000001;
const GLICKO2_SCALE: f64 = 173.7178;

#[derive(Clone, Debug)]
pub struct Rating {
    pub rating: f64,
    pub deviation: f64,
    pub volatility: f64,
}

impl Default for Rating {
    fn default() -> Self {
        Rating {
            rating: 1500.0,
            deviation: 350.0,
            volatility: 0.06,
        }
    }
}

#[derive(Clone, Debug)]
pub struct RatingResult {
    pub new_rating: f64,
    pub new_deviation: f64,
    pub new_volatility: f64,
}

/// Calculate new rating after a single game.
///
/// `score`: 1.0 = win, 0.0 = loss, 0.5 = draw
pub fn calculate_new_rating(player: &Rating, opponent: &Rating, score: f64) -> RatingResult {
    // Step 1: Convert to Glicko-2 scale
    let mu = (player.rating - 1500.0) / GLICKO2_SCALE;
    let phi = player.deviation / GLICKO2_SCALE;
    let sigma = player.volatility;

    let mu_j = (opponent.rating - 1500.0) / GLICKO2_SCALE;
    let phi_j = opponent.deviation / GLICKO2_SCALE;

    // Step 2: Compute variance (v)
    let g_phi_j = g(phi_j);
    let e_val = e(mu, mu_j, g_phi_j);
    let v = 1.0 / (g_phi_j * g_phi_j * e_val * (1.0 - e_val));

    // Step 3: Compute estimated improvement (delta)
    let delta = v * g_phi_j * (score - e_val);

    // Step 4: Compute new volatility
    let new_sigma = compute_new_volatility(sigma, phi, v, delta);

    // Step 5: Update rating deviation to new pre-rating period value
    let phi_star = (phi * phi + new_sigma * new_sigma).sqrt();

    // Step 6: Update rating and RD
    let new_phi = 1.0 / (1.0 / (phi_star * phi_star) + 1.0 / v).sqrt();
    let new_mu = mu + new_phi * new_phi * g_phi_j * (score - e_val);

    // Step 7: Convert back to Glicko scale
    RatingResult {
        new_rating: new_mu * GLICKO2_SCALE + 1500.0,
        new_deviation: new_phi * GLICKO2_SCALE,
        new_volatility: new_sigma,
    }
}

/// g(phi) function from Glicko-2
fn g(phi: f64) -> f64 {
    1.0 / (1.0 + 3.0 * phi * phi / (PI * PI)).sqrt()
}

/// E(mu, mu_j, phi_j) — expected score
fn e(mu: f64, mu_j: f64, g_phi_j: f64) -> f64 {
    1.0 / (1.0 + (-g_phi_j * (mu - mu_j)).exp())
}

/// Compute new volatility using the Illinois algorithm
fn compute_new_volatility(sigma: f64, phi: f64, v: f64, delta: f64) -> f64 {
    let a = (sigma * sigma).ln();
    let delta_sq = delta * delta;
    let phi_sq = phi * phi;

    let f = |x: f64| -> f64 {
        let ex = x.exp();
        let num1 = ex * (delta_sq - phi_sq - v - ex);
        let den1 = 2.0 * (phi_sq + v + ex).powi(2);
        num1 / den1 - (x - a) / (TAU * TAU)
    };

    let mut big_a = a;
    let mut big_b: f64;

    if delta_sq > phi_sq + v {
        big_b = (delta_sq - phi_sq - v).ln();
    } else {
        let mut k = 1;
        while f(a - k as f64 * TAU) < 0.0 {
            k += 1;
        }
        big_b = a - k as f64 * TAU;
    }

    let mut f_a = f(big_a);
    let mut f_b = f(big_b);

    while (big_b - big_a).abs() > CONVERGENCE_TOLERANCE {
        let big_c = big_a + (big_a - big_b) * f_a / (f_b - f_a);
        let f_c = f(big_c);

        if f_c * f_b <= 0.0 {
            big_a = big_b;
            f_a = f_b;
        } else {
            f_a /= 2.0;
        }

        big_b = big_c;
        f_b = f_c;
    }

    (big_a / 2.0).exp()
}
