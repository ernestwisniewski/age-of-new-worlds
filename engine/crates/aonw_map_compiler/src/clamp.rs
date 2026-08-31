use crate::{ClampReport, CompiledTerrain, RasterRegion, TerrainClampError};

impl CompiledTerrain {
    /// Clamps only the requested part of caller-owned final terrain.
    ///
    /// The generated base is never copied into `final_heights`. The method
    /// applies only the independent min/max constraints and rejects non-finite
    /// input transactionally before changing any sample.
    ///
    /// # Errors
    ///
    /// Returns [`TerrainClampError`] for wrong dimensions, an invalid region,
    /// or non-finite manual input.
    pub fn clamp_final_region(
        &self,
        final_heights: &mut [f32],
        region: RasterRegion,
    ) -> Result<ClampReport, TerrainClampError> {
        let expected = self.base().values().len();
        if final_heights.len() != expected {
            return Err(TerrainClampError::LengthMismatch {
                expected,
                found: final_heights.len(),
            });
        }
        validate_region(region, self.base().width(), self.base().height())?;

        let indices = region_indices(region, self.base().width());
        for index in indices.clone() {
            if !final_heights[index].is_finite() {
                return Err(TerrainClampError::NonFiniteFinalHeight { index });
            }
        }

        let mut changed_samples = 0;
        for index in indices {
            let current = final_heights[index];
            let constrained = current.clamp(self.min().values()[index], self.max().values()[index]);
            if constrained.to_bits() != current.to_bits() {
                final_heights[index] = constrained;
                changed_samples += 1;
            }
        }
        Ok(ClampReport::new(changed_samples))
    }
}

fn validate_region(
    region: RasterRegion,
    raster_width: u32,
    raster_height: u32,
) -> Result<(), TerrainClampError> {
    let end_x = region
        .x()
        .checked_add(region.width())
        .ok_or(TerrainClampError::InvalidRegion)?;
    let end_y = region
        .y()
        .checked_add(region.height())
        .ok_or(TerrainClampError::InvalidRegion)?;
    if region.width() == 0 || region.height() == 0 || end_x > raster_width || end_y > raster_height
    {
        return Err(TerrainClampError::InvalidRegion);
    }
    Ok(())
}

fn region_indices(region: RasterRegion, raster_width: u32) -> impl Clone + Iterator<Item = usize> {
    let raster_width = usize::try_from(raster_width).expect("u32 fits usize");
    (region.y()..region.y() + region.height()).flat_map(move |y| {
        let row_start = usize::try_from(y).expect("u32 fits usize") * raster_width;
        (region.x()..region.x() + region.width())
            .map(move |x| row_start + usize::try_from(x).expect("u32 fits usize"))
    })
}
