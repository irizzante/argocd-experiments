# App of ApplicationSet Order

The App of ApplicationSet Order shows how to order ApplicationSet creation by using sync waves.

Each folder contains a root ApplicationSet which creates a root Application which finally creates the ApplicationSets:

root ApplicationSet -> root Application -> ApplicationSet 1 -> ApplicationSet 2 -> ApplicationSet 3...

Folder `sync-waves` contains the sync-waves example. Sync-waves are applied at the ApplicationSet 1, 2, 3... level so that the root Application can order them.

ArgoCD doesn't work as expected this way and it doesn't wait for the first ApplicationSet to be ready before creating the next one.

Foder `eventual-consistency` contains the eventual consistency example. ApplicationSet 1, 2, 3... are created at the same time and we rely on the `retry` field to make ArgoCD retry deploying each ApplicationSet until it finally succeeds. 

Note that **it's still possible** to apply sync-waves to manage the deletion order of the ApplicationSets.
In this case ArgoCD **actually waits** for each ApplicationSet to be deleted before proceeding to the next one.