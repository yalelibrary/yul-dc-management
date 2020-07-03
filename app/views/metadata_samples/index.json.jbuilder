# frozen_string_literal: true

json.array! @metadata_samples, partial: "metadata_samples/metadata_sample", as: :metadata_sample
