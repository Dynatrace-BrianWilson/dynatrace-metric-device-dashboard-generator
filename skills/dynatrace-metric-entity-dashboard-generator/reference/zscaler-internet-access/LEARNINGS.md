# Learnings

- OpenPipeline topology extraction on Gen3 requires builtin:openpipeline.bizevents.pipelines and builtin:openpipeline.bizevents.routing settings objects.
- Keep map regions disabled using showRegions=false to avoid map data loading failures.
- Use event.provider filters on every dashboard query to keep scan volume predictable.
- Inject in 500-event chunks to stay under payload limits.
